package io.nextsense.android.base;

import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.util.Log;

import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;
import com.google.common.util.concurrent.SettableFuture;
import com.welie.blessed.BluetoothCentralManagerCallback;
import com.welie.blessed.BluetoothPeripheral;
import com.welie.blessed.BluetoothPeripheralCallback;
import com.welie.blessed.GattStatus;
import com.welie.blessed.HciStatus;
import com.welie.blessed.PhyType;
import io.nextsense.android.base.communication.ble.BleCentralManagerProxy;
import io.nextsense.android.base.communication.ble.BlePeripheralCallbackProxy;
import io.nextsense.android.base.devices.NextSenseDevice;
import java.util.HashSet;
import java.util.Objects;
import java.util.Set;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Executors;

import org.jetbrains.annotations.NotNull;

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

  private static final String TAG = Device.class.getSimpleName();

  private final NextSenseDevice nextSenseDevice;
  private final BluetoothPeripheral btPeripheral;
  private final BleCentralManagerProxy centralManagerProxy;
  private final Set<DeviceStateChangeListener> deviceStateChangeListeners = new HashSet<>();
  private final DeviceInfo deviceInfo = new DeviceInfo();
  private final DeviceSettings deviceSettings = new DeviceSettings();
  private final DeviceData deviceData = new DeviceData();
  private final BlePeripheralCallbackProxy callbackProxy = new BlePeripheralCallbackProxy();

  private DeviceState deviceState = DeviceState.DISCONNECTED;
  private boolean autoReconnect = false;
  private SettableFuture<DeviceState> deviceConnectionFuture;
  private SettableFuture<DeviceState> deviceDisconnectionFuture;

  public Device(BleCentralManagerProxy centralProxy, NextSenseDevice nextSenseDevice,
                BluetoothPeripheral btPeripheral) {
    this.centralManagerProxy = centralProxy;
    this.nextSenseDevice = nextSenseDevice;
    this.btPeripheral = btPeripheral;
    centralProxy.addPeripheralListener(bluetoothCentralManagerCallback, btPeripheral.getAddress());
    callbackProxy.addPeripheralCallbackListener(peripheralCallback);
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

  public ListenableFuture<DeviceMode> setMode(DeviceMode deviceMode) {
    if (deviceState != DeviceState.READY) {
      return Futures.immediateFailedFuture(new IllegalStateException(
          "Device needs to be in READY state to change its mode."));
    }
    return nextSenseDevice.changeMode(deviceMode);
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
    if (deviceState != DeviceState.DISCONNECTED) {
      return Futures.immediateFuture(deviceState);
    }
    deviceState = DeviceState.CONNECTING;
    this.autoReconnect = autoReconnect;
    deviceConnectionFuture = SettableFuture.create();
    centralManagerProxy.getCentralManager().connectPeripheral(
        btPeripheral, callbackProxy.getMainCallback());
    return deviceConnectionFuture;
  }

  /**
   * Disconnects the device. Cancels reconnection attempts if autoReconnect was set to true when
   * connecting.
   */
  public ListenableFuture<DeviceState> disconnect() {
    switch (deviceState) {
      case DISCONNECTED:
        return Futures.immediateFuture(DeviceState.DISCONNECTED);
      case CONNECTING:
        // fallthrough
      case CONNECTED:
        // fallthrough
      case READY:
        // fallthrough
      case IN_ERROR:
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
  public boolean setSettings(DeviceSettings deviceSettings) {
    return false;
  }

  /**
   * Methods to get the data or listen to new data.
   */
  public DeviceData getData() {
    return deviceData;
  }

  private void readyDevice(BluetoothPeripheral peripheral) {
    nextSenseDevice.setBluetoothPeripheralProxy(callbackProxy);
    Executors.newSingleThreadExecutor().submit(() -> {
      try {
        nextSenseDevice.connect(peripheral).get();
        deviceState = DeviceState.READY;
        deviceConnectionFuture.set(deviceState);
        notifyDeviceStateChangeListeners(DeviceState.READY);
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
    public void onConnectedPeripheral(@NotNull BluetoothPeripheral peripheral) {
      Log.d(TAG, "Connected with device " + peripheral.getName());
      deviceState = DeviceState.CONNECTED;
      notifyDeviceStateChangeListeners(DeviceState.CONNECTED);
    }

    @Override
    public void onConnectionFailed(@NotNull BluetoothPeripheral peripheral,
                                   @NotNull HciStatus status) {
      Log.w(TAG, "Connection with device " + peripheral.getName() + " failed. HCI status: " +
          status.toString());
      deviceState = DeviceState.DISCONNECTED;
      deviceConnectionFuture.set(deviceState);
      notifyDeviceStateChangeListeners(DeviceState.DISCONNECTED);
    }

    @Override
    public void onConnectingPeripheral(@NotNull BluetoothPeripheral peripheral) {
      Util.logd(TAG, "Device " + peripheral.getName() + " connecting.");
      deviceState = DeviceState.CONNECTING;
      notifyDeviceStateChangeListeners(DeviceState.CONNECTING);
    }

    @Override
    public void onDisconnectingPeripheral(@NotNull BluetoothPeripheral peripheral) {
      Util.logd(TAG, "Device " + peripheral.getName() + " disconnecting.");
      deviceState = DeviceState.DISCONNECTING;
      notifyDeviceStateChangeListeners(DeviceState.DISCONNECTING);
    }

    @Override
    public void onDisconnectedPeripheral(@NotNull BluetoothPeripheral peripheral,
                                         @NotNull HciStatus status) {
      Util.logd(TAG, "Device " + peripheral.getName() + " disconnected.");
      deviceState = DeviceState.DISCONNECTED;
      deviceDisconnectionFuture.set(deviceState);
      notifyDeviceStateChangeListeners(DeviceState.DISCONNECTED);
    }
  };

  private final BluetoothPeripheralCallback peripheralCallback = new BluetoothPeripheralCallback() {
    @Override
    public void onServicesDiscovered(@NotNull BluetoothPeripheral peripheral) {
      Util.logd(TAG, "Services discovered.");
      if (nextSenseDevice.getTargetMTU() != 23) {
        btPeripheral.requestMtu(nextSenseDevice.getTargetMTU());
      } else {
        // No need to change the MTU, device is ready to use.
        readyDevice(peripheral);
      }
    }

    @Override
    public void onNotificationStateUpdate(@NotNull BluetoothPeripheral peripheral,
                                          @NotNull BluetoothGattCharacteristic characteristic,
                                          @NotNull GattStatus status) {
    }

    @Override
    public void onCharacteristicUpdate(@NotNull BluetoothPeripheral peripheral, byte[] value,
                                       @NotNull BluetoothGattCharacteristic characteristic,
                                       @NotNull GattStatus status) {
      super.onCharacteristicUpdate(peripheral, value, characteristic, status);
    }

    @Override
    public void onCharacteristicWrite(@NotNull BluetoothPeripheral peripheral, byte[] value,
                                      @NotNull BluetoothGattCharacteristic characteristic,
                                      @NotNull GattStatus status) {
      super.onCharacteristicWrite(peripheral, value, characteristic, status);
    }

    @Override
    public void onDescriptorRead(@NotNull BluetoothPeripheral peripheral, byte[] value,
                                 @NotNull BluetoothGattDescriptor descriptor,
                                 @NotNull GattStatus status) {
      super.onDescriptorRead(peripheral, value, descriptor, status);
    }

    @Override
    public void onDescriptorWrite(@NotNull BluetoothPeripheral peripheral, byte[] value,
                                  @NotNull BluetoothGattDescriptor descriptor,
                                  @NotNull GattStatus status) {
      super.onDescriptorWrite(peripheral, value, descriptor, status);
    }

    @Override
    public void onReadRemoteRssi(@NotNull BluetoothPeripheral peripheral, int rssi,
                                 @NotNull GattStatus status) {
      super.onReadRemoteRssi(peripheral, rssi, status);
    }

    @Override
    public void onMtuChanged(@NotNull BluetoothPeripheral peripheral, int mtu,
                             @NotNull GattStatus status) {
      super.onMtuChanged(peripheral, mtu, status);
      Util.logd(TAG, "MTU changed to " + mtu);
      // Run the device specific connection and mark as ready.
      readyDevice(peripheral);
    }

    @Override
    public void onPhyUpdate(@NotNull BluetoothPeripheral peripheral, @NotNull PhyType txPhy,
                            @NotNull PhyType rxPhy, @NotNull GattStatus status) {
      super.onPhyUpdate(peripheral, txPhy, rxPhy, status);
      Util.logd(TAG, "PHY changed to tx: " + txPhy.name() + ", rx: " + rxPhy.name());
    }

    @Override
    public void onConnectionUpdated(@NotNull BluetoothPeripheral peripheral, int interval,
                                    int latency, int timeout, @NotNull GattStatus status) {
      super.onConnectionUpdated(peripheral, interval, latency, timeout, status);
      Util.logd(TAG, "Connection updated to interval: " + interval + ", latency: " + latency +
          ", timeout: " + timeout + ", gatt status: " + status);
    }
  };

  @Override
  public boolean equals(Object o) {
    if (this == o) return true;
    if (o == null || getClass() != o.getClass()) return false;
    Device device = (Device) o;
    return nextSenseDevice.equals(device.nextSenseDevice);
  }

  @Override
  public int hashCode() {
    return Objects.hash(nextSenseDevice);
  }
}
