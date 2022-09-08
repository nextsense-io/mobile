package io.nextsense.android.base.ble;

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

import java.time.Duration;
import java.util.Objects;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Executors;

import io.nextsense.android.base.Device;
import io.nextsense.android.base.DeviceData;
import io.nextsense.android.base.DeviceInfo;
import io.nextsense.android.base.DeviceMode;
import io.nextsense.android.base.DeviceSettings;
import io.nextsense.android.base.DeviceState;
import io.nextsense.android.base.communication.ble.BleCentralManagerProxy;
import io.nextsense.android.base.communication.ble.BlePeripheralCallbackProxy;
import io.nextsense.android.base.communication.ble.BluetoothStateManager;
import io.nextsense.android.base.communication.ble.ReconnectionManager;
import io.nextsense.android.base.devices.NextSenseDevice;
import io.nextsense.android.base.devices.xenon.StartStreamingCommand;
import io.nextsense.android.base.devices.xenon.XenonDevice;
import io.nextsense.android.base.utils.Util;

/**
 * Main device interface that is shared for any device. Device specific functions are encapsulated
 * in the NextSenseDevice interface which needs to be given at construction time.
 */
public class BleDevice extends Device {

  public static final Duration RECONNECTION_ATTEMPTS_INTERVAL = Duration.ofSeconds(30);
  private static final String TAG = BleDevice.class.getSimpleName();

  private final NextSenseDevice nextSenseDevice;
  private final BluetoothPeripheral btPeripheral;
  private final BleCentralManagerProxy centralManagerProxy;
  private final DeviceInfo deviceInfo = new DeviceInfo();
  private final BlePeripheralCallbackProxy callbackProxy = new BlePeripheralCallbackProxy();
  private final ReconnectionManager reconnectionManager;
  private final ListeningExecutorService executorService =
      MoreExecutors.listeningDecorator(Executors.newCachedThreadPool());

  private DeviceState deviceState = DeviceState.DISCONNECTED;
  private boolean autoReconnect = true;
  private DisconnectionStatus disconnectionStatus = DisconnectionStatus.NOT_DISCONNECTING;
  private DeviceSettings deviceSettings;
  private DeviceSettings savedDeviceSettings;

  public BleDevice(BleCentralManagerProxy centralProxy, BluetoothStateManager bluetoothStateManager,
                   NextSenseDevice nextSenseDevice, BluetoothPeripheral btPeripheral,
                   ReconnectionManager reconnectionManager) {
    this.centralManagerProxy = centralProxy;
    this.nextSenseDevice = nextSenseDevice;
    this.btPeripheral = btPeripheral;
    centralProxy.addPeripheralListener(bluetoothCentralManagerCallback, btPeripheral.getAddress());
    callbackProxy.addPeripheralCallbackListener(peripheralCallback);
    this.reconnectionManager = reconnectionManager;
  }

  @Override
  public String getName() {
    return btPeripheral.getName();
  }

  @Override
  public String getAddress() {
    return btPeripheral.getAddress();
  }

  @Override
  public DeviceState getState() {
    return deviceState;
  }

  @Override
  public DeviceMode getMode() {
    return nextSenseDevice.getDeviceMode();
  }

  @Override
  public boolean requestDeviceState() {
    if (deviceState != DeviceState.READY) {
      return false;
    }
    return nextSenseDevice.requestDeviceInternalState();
  }

  @Override
  public ListenableFuture<Boolean> startStreaming(
      boolean uploadToCloud, @Nullable String userBigTableKey, @Nullable String dataSessionId,
      @Nullable String earbudsConfig) {
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
    return executorService.submit(() ->
        nextSenseDevice.startStreaming(uploadToCloud, userBigTableKey, dataSessionId, earbudsConfig,
            parametersBundle).get());
  }

  @Override
  public ListenableFuture<Boolean> stopStreaming() {
    if (deviceState != DeviceState.READY) {
      return Futures.immediateFailedFuture(new IllegalStateException(
          "Device needs to be in READY state to change its mode."));
    }
    return nextSenseDevice.stopStreaming();
  }

  @Override
  public ListenableFuture<Boolean> setImpedanceConfig(
      DeviceSettings.ImpedanceMode impedanceMode, @Nullable Integer channelNumber,
      @Nullable Integer frequencyDivider) {
    // Check if nothing to do. For external current, channel number and frequency divider can change
    // so re-apply in any case.
    if (deviceSettings.getImpedanceMode() == impedanceMode &&
        impedanceMode != DeviceSettings.ImpedanceMode.ON_EXTERNAL_CURRENT) {
      return Futures.immediateFuture(true);
    }
    if (savedDeviceSettings == null) {
      savedDeviceSettings = new DeviceSettings(deviceSettings);
    }
    DeviceSettings newDeviceSettings = new DeviceSettings(deviceSettings);
    newDeviceSettings.setImpedanceMode(impedanceMode);
    if (impedanceMode == DeviceSettings.ImpedanceMode.ON_EXTERNAL_CURRENT) {
      if (channelNumber == null || frequencyDivider == null) {
        Log.e(TAG, "Need to provide a channel number and impedance frequency for External Current" +
            " Impedance Mode.");
        return Futures.immediateFuture(false);
      }
      newDeviceSettings.setEnabledChannels(ImmutableList.of(channelNumber));
      newDeviceSettings.setImpedanceDivider(frequencyDivider);
    }
    return setSettings(newDeviceSettings);
  }

  @Override
  public ListenableFuture<Boolean> startImpedance(
      DeviceSettings.ImpedanceMode impedanceMode, @Nullable Integer channelNumber,
      @Nullable Integer frequencyDivider) {
    if (impedanceMode == DeviceSettings.ImpedanceMode.OFF) {
      return Futures.immediateFuture(false);
    }
    return executorService.submit(() -> {
      boolean settingsSet =
          setImpedanceConfig(impedanceMode, channelNumber, frequencyDivider).get();
      if (settingsSet) {
        return startStreaming(/*uploadToCloud=*/false, /*userBigTableKey=*/null,
            /*dataSessionId=*/null, /*earbudsConfig=*/null).get();
      } else {
        return false;
      }
    });
  }

  @Override
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

  /**
   * Tries to connect the device.
   *
   * @param autoReconnect if true will try to reconnect when the connection is lost.
   */
  @Override
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
  @Override
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
  @Override
  public DeviceInfo getInfo() {
    return deviceInfo;
  }

  /**
   * Returns the {@link DeviceSettings} currently in place on the {@link BleDevice}.
   */
  @Override
  public DeviceSettings getSettings() {
    return deviceSettings;
  }

  /**
   * Sets the deviceSettings in the device firmware. The device must be in {@code DeviceMode.IDLE}
   * mode when invoking this.
   */
  @Override
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
  @Override
  public DeviceData getData() {
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
      if (deviceConnectionFuture != null) {
        deviceConnectionFuture.set(deviceState);
      }
      if (deviceState != DeviceState.DISCONNECTED) {
        deviceState = DeviceState.DISCONNECTED;
        notifyDeviceStateChangeListeners(DeviceState.DISCONNECTED);
      }
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
        Util.logd(TAG, "Hard disconnect, try to reconnect.");
        disconnectionStatus = DisconnectionStatus.HARD;
        if (autoReconnect) {
          reconnectionManager.startReconnecting(peripheral, callbackProxy.getMainCallback());
        } else {
          Util.logd(TAG, "autoReconnect is OFF, no need to try to reconnect.");
        }
      } else {
        Util.logd(TAG, "Disconnection was by request, no need to try to reconnect.");
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
      if (nextSenseDevice.getTargetMTU() != 23 && btPeripheral.getCurrentMtu() <= 23) {
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
    return getAddress().equals(((BleDevice) other).getAddress());
  }

  @Override
  public int hashCode() {
    return Objects.hash(getAddress());
  }
}
