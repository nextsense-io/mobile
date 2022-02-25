package io.nextsense.android.base;

import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.os.Bundle;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.google.common.collect.ImmutableList;
import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;
import com.google.common.util.concurrent.ListeningExecutorService;
import com.google.common.util.concurrent.MoreExecutors;
import com.google.common.util.concurrent.SettableFuture;
import com.welie.blessed.BluetoothCentralManagerCallback;
import com.welie.blessed.BluetoothPeripheral;
import com.welie.blessed.BluetoothPeripheralCallback;
import com.welie.blessed.GattStatus;
import com.welie.blessed.HciStatus;
import com.welie.blessed.PhyType;
import io.nextsense.android.base.communication.ble.BleCentralManagerProxy;
import io.nextsense.android.base.communication.ble.BlePeripheralCallbackProxy;
import io.nextsense.android.base.communication.ble.ReconnectionManager;
import io.nextsense.android.base.devices.NextSenseDevice;
import io.nextsense.android.base.devices.xenon.StartStreamingCommand;
import io.nextsense.android.base.devices.xenon.XenonDevice;
import io.nextsense.android.base.utils.Util;

import java.time.Duration;
import java.util.HashSet;
import java.util.Objects;
import java.util.Set;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Executors;

/**
 * Main device interface that is shared for any device. Device specific functions are encapsulated
 * in the NextSenseDevice interface which needs to be given at construction time.
 */
public class Device {

  /**
   * Interface to be notified of device changes.
   */
  public interface DeviceStateChangeListener {
    void onDeviceStateChange(DeviceState deviceState);
  }

  public enum DisconnectionStatus {
    NOT_DISCONNECTING,  // Not connected yet.
    BY_REQUEST,  // Disconnect initiated by the user.
    HARD  // Disconnect not initiated by the user.
  }

  private static final String TAG = Device.class.getSimpleName();
  private static final Duration RECONNECTION_ATTEMPTS_INTERVAL = Duration.ofSeconds(30);

  private final NextSenseDevice nextSenseDevice;
  private final BluetoothPeripheral btPeripheral;
  private final BleCentralManagerProxy centralManagerProxy;
  private final Set<DeviceStateChangeListener> deviceStateChangeListeners = new HashSet<>();
  private final DeviceInfo deviceInfo = new DeviceInfo();
  // TODO(eric): Inject DB? Frequency?
  // private final DeviceData deviceData = new DeviceData();
  private final BlePeripheralCallbackProxy callbackProxy = new BlePeripheralCallbackProxy();
  private final ReconnectionManager reconnectionManager;
  private final ListeningExecutorService executorService =
      MoreExecutors.listeningDecorator(Executors.newCachedThreadPool());

  private DeviceState deviceState = DeviceState.DISCONNECTED;
  private boolean autoReconnect = false;
  private SettableFuture<DeviceState> deviceConnectionFuture;
  private SettableFuture<DeviceState> deviceDisconnectionFuture;
  private DisconnectionStatus disconnectionStatus = DisconnectionStatus.NOT_DISCONNECTING;
  private DeviceSettings deviceSettings;
  private DeviceSettings savedDeviceSettings;

  public Device(BleCentralManagerProxy centralProxy, NextSenseDevice nextSenseDevice,
                BluetoothPeripheral btPeripheral) {
    this.centralManagerProxy = centralProxy;
    this.nextSenseDevice = nextSenseDevice;
    this.btPeripheral = btPeripheral;
    centralProxy.addPeripheralListener(bluetoothCentralManagerCallback, btPeripheral.getAddress());
    callbackProxy.addPeripheralCallbackListener(peripheralCallback);
    reconnectionManager = ReconnectionManager.create(
        centralManagerProxy, RECONNECTION_ATTEMPTS_INTERVAL);
  }

  public String getName() {
    return btPeripheral.getName();
  }

  public String getAddress() {
    return btPeripheral.getAddress();
  }

  public DeviceState getState() {
    return deviceState;
  }

  public DeviceMode getMode() {
    return nextSenseDevice.getDeviceMode();
  }

  public boolean requestDeviceState() {
    if (deviceState != DeviceState.READY) {
      return false;
    }
    return nextSenseDevice.requestDeviceInternalState();
  }

  public ListenableFuture<Boolean> startStreaming(
      boolean uploadToCloud, @Nullable String userBigTableKey, @Nullable String dataSessionId) {
    if (deviceState != DeviceState.READY) {
      return Futures.immediateFailedFuture(new IllegalStateException(
          "Device needs to be in READY state to change its mode."));
    }
    Bundle parametersBundle = new Bundle();
    // TODO(eric): Should have common parameters that then get translated to device specific command
    //             sets.
    if (uploadToCloud) {
      parametersBundle.putSerializable(XenonDevice.STREAM_START_MODE_KEY,
          StartStreamingCommand.StartMode.WITH_LOGGING);
    } else {
      parametersBundle.putSerializable(XenonDevice.STREAM_START_MODE_KEY,
          StartStreamingCommand.StartMode.NO_LOGGING);
    }
    return nextSenseDevice.startStreaming(uploadToCloud, userBigTableKey, dataSessionId,
        parametersBundle);
  }

  public ListenableFuture<Boolean> stopStreaming() {
    if (deviceState != DeviceState.READY) {
      return Futures.immediateFailedFuture(new IllegalStateException(
          "Device needs to be in READY state to change its mode."));
    }
    return nextSenseDevice.stopStreaming();
  }

  public ListenableFuture<Boolean> startImpedance(int channelNumber, int frequencyDivider) {
    return executorService.submit(() -> {
      if (savedDeviceSettings == null) {
        savedDeviceSettings = new DeviceSettings(deviceSettings);
      }
      DeviceSettings newDeviceSettings = new DeviceSettings(deviceSettings);
      newDeviceSettings.setImpedanceMode(true);
      newDeviceSettings.setImpedanceDivider(frequencyDivider);
      newDeviceSettings.setEnabledChannels(ImmutableList.of(channelNumber));
      boolean settingsSet = setSettings(newDeviceSettings).get();
      if (settingsSet) {
        return startStreaming(/*uploadToCloud=*/false, /*userBigTableKey=*/null,
            /*dataSessionId=*/null).get();
      } else {
        return false;
      }
    });
  }

  public ListenableFuture<Boolean> stopImpedance() {
    return executorService.submit(() -> {
      boolean stoppedStreaming = stopStreaming().get();
      if (stoppedStreaming) {
        boolean settingsSet = setSettings(savedDeviceSettings).get();
        if (settingsSet) {
          savedDeviceSettings = null;
          return true;
        }
      }
      return false;
    });
  }

  public void addOnDeviceStateChangeListener(DeviceStateChangeListener listener) {
    deviceStateChangeListeners.add(listener);
  }

  public void removeOnDeviceStateChangeListener(DeviceStateChangeListener listener) {
    deviceStateChangeListeners.remove(listener);
  }

  private void notifyDeviceStateChangeListeners(DeviceState deviceState) {
    for (DeviceStateChangeListener listener : deviceStateChangeListeners) {
      listener.onDeviceStateChange(deviceState);
    }
  }

  /**
   * Tries to connect the device.
   *
   * @param autoReconnect if true will try to reconnect when the connection is lost.
   */
  public ListenableFuture<DeviceState> connect(boolean autoReconnect) {
    Util.logd(TAG, "connect start");
    if (deviceState != DeviceState.DISCONNECTED) {
      return Futures.immediateFuture(deviceState);
    }
    if (reconnectionManager.isReconnecting()) {
      reconnectionManager.stopReconnecting();
    }
    deviceState = DeviceState.CONNECTING;
    this.autoReconnect = autoReconnect;
    deviceConnectionFuture = SettableFuture.create();
    centralManagerProxy.getCentralManager().connectPeripheral(
        btPeripheral, callbackProxy.getMainCallback());
    Util.logd(TAG, "connect returning future");
    return deviceConnectionFuture;
  }

  /**
   * Disconnects the device. Cancels reconnection attempts if autoReconnect was set to true when
   * connecting.
   */
  public ListenableFuture<DeviceState> disconnect() {
    if (reconnectionManager.isReconnecting()) {
      reconnectionManager.stopReconnecting();
    }
    switch (deviceState) {
      case DISCONNECTED:
        return Futures.immediateFuture(DeviceState.DISCONNECTED);
      case IN_ERROR:
        // fallthrough
      case CONNECTING:
        // fallthrough
      case CONNECTED:
        // fallthrough
      case READY:
        // fallthrough
        disconnectionStatus = DisconnectionStatus.BY_REQUEST;
        this.deviceDisconnectionFuture = SettableFuture.create();
        nextSenseDevice.disconnect(btPeripheral);
        btPeripheral.cancelConnection();
        break;
      case DISCONNECTING:
        // Already disconnecting, return the same future.
        break;
    }
    return deviceDisconnectionFuture;
  }

  /**
   * Gets the {@link DeviceInfo}.
   */
  public DeviceInfo getInfo() {
    return deviceInfo;
  }

  /**
   * Returns the {@link DeviceSettings} currently in place on the {@link Device}.
   */
  public DeviceSettings getSettings() {
    return deviceSettings;
  }

  /**
   * Sets the deviceSettings in the device firmware. The device must be in {@code DeviceMode.IDLE}
   * mode when invoking this.
   */
  public ListenableFuture<Boolean> setSettings(DeviceSettings newDeviceSettings) {
    if (nextSenseDevice.getDeviceMode() != DeviceMode.IDLE) {
      return Futures.immediateFuture(false);
    }
    return executorService.submit(() -> {
      boolean applied = nextSenseDevice.applyDeviceSettings(newDeviceSettings).get();
      if (applied) {
        this.deviceSettings = newDeviceSettings;
      }
      return applied;
    });
  }

  /**
   * Methods to get the data or listen to new data.
   */
  public DeviceData getData() {
    // return deviceData;
    return null;
  }

  private void readyDevice(BluetoothPeripheral peripheral) {
    nextSenseDevice.setBluetoothPeripheralProxy(callbackProxy);
    Executors.newSingleThreadExecutor().submit(() -> {
      try {
        nextSenseDevice.connect(peripheral,
            disconnectionStatus == DisconnectionStatus.HARD).get();
        deviceSettings = new DeviceSettings(nextSenseDevice.loadDeviceSettings().get());
        deviceState = DeviceState.READY;
        deviceConnectionFuture.set(deviceState);
        notifyDeviceStateChangeListeners(DeviceState.READY);
        if (disconnectionStatus == DisconnectionStatus.HARD && getMode() == DeviceMode.STREAMING) {
          nextSenseDevice.restartStreaming();
        }
        disconnectionStatus = DisconnectionStatus.NOT_DISCONNECTING;
      } catch (ExecutionException e) {
        Log.e(TAG, "Failed to connect device: " + e.getMessage());
        deviceConnectionFuture.setException(e);
      } catch (InterruptedException e) {
        deviceConnectionFuture.setException(e);
        Thread.currentThread().interrupt();
      }
    });
  }

  private final BluetoothCentralManagerCallback bluetoothCentralManagerCallback =
      new BluetoothCentralManagerCallback() {
    @Override
    public void onConnectedPeripheral(@NonNull BluetoothPeripheral peripheral) {
      Log.d(TAG, "Connected with device " + peripheral.getName());
      deviceState = DeviceState.CONNECTED;
      notifyDeviceStateChangeListeners(DeviceState.CONNECTED);
      if (reconnectionManager.isReconnecting()) {
        reconnectionManager.stopReconnecting();
      }
    }

    @Override
    public void onConnectionFailed(@NonNull BluetoothPeripheral peripheral,
                                   @NonNull HciStatus status) {
      Log.w(TAG, "Connection with device " + peripheral.getName() + " failed. HCI status: " +
          status);
      deviceState = DeviceState.DISCONNECTED;
      if (deviceConnectionFuture != null) {
        deviceConnectionFuture.set(deviceState);
      }
      notifyDeviceStateChangeListeners(DeviceState.DISCONNECTED);
    }

    @Override
    public void onConnectingPeripheral(@NonNull BluetoothPeripheral peripheral) {
      Util.logd(TAG, "Device " + peripheral.getName() + " connecting.");
      deviceState = DeviceState.CONNECTING;
      notifyDeviceStateChangeListeners(DeviceState.CONNECTING);
    }

    @Override
    public void onDisconnectingPeripheral(@NonNull BluetoothPeripheral peripheral) {
      Util.logd(TAG, "Device " + peripheral.getName() + " disconnecting.");
      deviceState = DeviceState.DISCONNECTING;
      notifyDeviceStateChangeListeners(DeviceState.DISCONNECTING);
    }

    @Override
    public void onDisconnectedPeripheral(@NonNull BluetoothPeripheral peripheral,
                                         @NonNull HciStatus status) {
      Util.logd(TAG, "Device " + peripheral.getName() + " disconnected.");
      if (disconnectionStatus != DisconnectionStatus.BY_REQUEST) {
        disconnectionStatus = DisconnectionStatus.HARD;
        if (autoReconnect) {
          reconnectionManager.startReconnecting(peripheral, callbackProxy.getMainCallback());
        }
      }
      deviceState = DeviceState.DISCONNECTED;
      if (deviceDisconnectionFuture != null) {
        deviceDisconnectionFuture.set(deviceState);
      }
      notifyDeviceStateChangeListeners(DeviceState.DISCONNECTED);
    }
  };

  private final BluetoothPeripheralCallback peripheralCallback = new BluetoothPeripheralCallback() {
    @Override
    public void onServicesDiscovered(@NonNull BluetoothPeripheral peripheral) {
      Util.logd(TAG, "Services discovered.");
      if (nextSenseDevice.getTargetMTU() != 23) {
        btPeripheral.requestMtu(nextSenseDevice.getTargetMTU());
      } else {
        // No need to change the MTU, device is ready to use.
        readyDevice(peripheral);
      }
    }

    @Override
    public void onNotificationStateUpdate(@NonNull BluetoothPeripheral peripheral,
                                          @NonNull BluetoothGattCharacteristic characteristic,
                                          @NonNull GattStatus status) {
      super.onNotificationStateUpdate(peripheral, characteristic, status);
    }

    @Override
    public void onCharacteristicUpdate(@NonNull BluetoothPeripheral peripheral,
                                       @NonNull byte[] value,
                                       @NonNull BluetoothGattCharacteristic characteristic,
                                       @NonNull GattStatus status) {
      super.onCharacteristicUpdate(peripheral, value, characteristic, status);
    }

    @Override
    public void onCharacteristicWrite(@NonNull BluetoothPeripheral peripheral,
                                      @NonNull byte[] value,
                                      @NonNull BluetoothGattCharacteristic characteristic,
                                      @NonNull GattStatus status) {
      super.onCharacteristicWrite(peripheral, value, characteristic, status);
    }

    @Override
    public void onDescriptorRead(@NonNull BluetoothPeripheral peripheral, @NonNull byte[] value,
                                 @NonNull BluetoothGattDescriptor descriptor,
                                 @NonNull GattStatus status) {
      super.onDescriptorRead(peripheral, value, descriptor, status);
    }

    @Override
    public void onDescriptorWrite(@NonNull BluetoothPeripheral peripheral, @NonNull byte[] value,
                                  @NonNull BluetoothGattDescriptor descriptor,
                                  @NonNull GattStatus status) {
      super.onDescriptorWrite(peripheral, value, descriptor, status);
    }

    @Override
    public void onReadRemoteRssi(@NonNull BluetoothPeripheral peripheral, int rssi,
                                 @NonNull GattStatus status) {
      super.onReadRemoteRssi(peripheral, rssi, status);
    }

    @Override
    public void onMtuChanged(@NonNull BluetoothPeripheral peripheral, int mtu,
                             @NonNull GattStatus status) {
      super.onMtuChanged(peripheral, mtu, status);
      Util.logd(TAG, "MTU changed to " + mtu);
      // Run the device specific connection and mark as ready.
      readyDevice(peripheral);
    }

    @Override
    public void onPhyUpdate(@NonNull BluetoothPeripheral peripheral, @NonNull PhyType txPhy,
                            @NonNull PhyType rxPhy, @NonNull GattStatus status) {
      super.onPhyUpdate(peripheral, txPhy, rxPhy, status);
      Util.logd(TAG, "PHY changed to tx: " + txPhy.name() + ", rx: " + rxPhy.name());
    }

    @Override
    public void onConnectionUpdated(@NonNull BluetoothPeripheral peripheral, int interval,
                                    int latency, int timeout, @NonNull GattStatus status) {
      super.onConnectionUpdated(peripheral, interval, latency, timeout, status);
      Util.logd(TAG, "Connection updated to interval: " + interval + ", latency: " + latency +
          ", timeout: " + timeout + ", gatt status: " + status);
    }
  };

  @Override
  public boolean equals(Object other) {
    if (this == other) return true;
    if (other == null || getClass() != other.getClass()) return false;
    return getAddress().equals(((Device) other).getAddress());
  }

  @Override
  public int hashCode() {
    return Objects.hash(getAddress());
  }
}
