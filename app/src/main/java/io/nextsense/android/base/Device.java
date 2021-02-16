package io.nextsense.android.base;

import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;

import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.SettableFuture;
import com.welie.blessed.BluetoothCentral;
import com.welie.blessed.BluetoothPeripheral;
import com.welie.blessed.BluetoothPeripheralCallback;

import java.util.concurrent.Future;

/**
 * NextSense main device interface.
 */
public class Device {

  private final DeviceType deviceType;
  private final BluetoothPeripheral btPeripheral;
  private final BluetoothCentral central;

  private DeviceMode deviceMode = DeviceMode.IDLE;
  private DeviceState deviceState = DeviceState.DISCONNECTED;
  private DeviceInfo deviceInfo = new DeviceInfo();
  private DeviceSettings deviceSettings = new DeviceSettings();
  private DeviceData deviceData = new DeviceData();
  private boolean autoReconnect = false;
  private SettableFuture<DeviceState> deviceStateFuture;

  public Device(
      DeviceType deviceType, BluetoothPeripheral btPeripheral, BluetoothCentral bluetoothCentral) {
    this.deviceType = deviceType;
    this.btPeripheral = btPeripheral;
    this.central = bluetoothCentral;
  }

  public DeviceState getState() {
    return deviceState;
  }

  public DeviceMode getMode() {
    return deviceMode;
  }

  public Future<DeviceMode> setMode(DeviceMode deviceMode) {
    this.deviceMode = deviceMode;
    return Futures.immediateFuture(deviceMode);
  }

  /**
   * Tries to connect the device.
   * @param autoReconnect if true will try to reconnect when the connection is lost.
   */
  public Future<DeviceState> connect(boolean autoReconnect) {
    if (deviceState != DeviceState.DISCONNECTED) {
      return Futures.immediateFuture(deviceState);
    }
    deviceState = DeviceState.CONNECTING;
    this.autoReconnect = autoReconnect;
    //central.
    central.connectPeripheral(btPeripheral, btCallback);
    deviceStateFuture = SettableFuture.create();
    return deviceStateFuture;
  }

  /**
   * Disconnects the device. Cancels reconnection attempts if autoReconnect was set to true when
   * connecting.
   */
  public Future<DeviceState> disconnect() {
    return Futures.immediateFuture(DeviceState.DISCONNECTED);
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

  private BluetoothPeripheralCallback btCallback = new BluetoothPeripheralCallback() {
    @Override
    public void onServicesDiscovered(BluetoothPeripheral peripheral) {
      super.onServicesDiscovered(peripheral);
      deviceState = DeviceState.CONNECTED;
      deviceStateFuture.set(deviceState);
    }

    @Override
    public void onNotificationStateUpdate(BluetoothPeripheral peripheral, BluetoothGattCharacteristic characteristic, int status) {
      super.onNotificationStateUpdate(peripheral, characteristic, status);
    }

    @Override
    public void onCharacteristicUpdate(BluetoothPeripheral peripheral, byte[] value, BluetoothGattCharacteristic characteristic, int status) {
      super.onCharacteristicUpdate(peripheral, value, characteristic, status);
    }

    @Override
    public void onCharacteristicWrite(BluetoothPeripheral peripheral, byte[] value, BluetoothGattCharacteristic characteristic, int status) {
      super.onCharacteristicWrite(peripheral, value, characteristic, status);
    }

    @Override
    public void onDescriptorRead(BluetoothPeripheral peripheral, byte[] value, BluetoothGattDescriptor descriptor, int status) {
      super.onDescriptorRead(peripheral, value, descriptor, status);
    }

    @Override
    public void onDescriptorWrite(BluetoothPeripheral peripheral, byte[] value, BluetoothGattDescriptor descriptor, int status) {
      super.onDescriptorWrite(peripheral, value, descriptor, status);
    }

    @Override
    public void onBondingStarted(BluetoothPeripheral peripheral) {
      super.onBondingStarted(peripheral);
    }

    @Override
    public void onBondingSucceeded(BluetoothPeripheral peripheral) {
      super.onBondingSucceeded(peripheral);
    }

    @Override
    public void onBondingFailed(BluetoothPeripheral peripheral) {
      super.onBondingFailed(peripheral);
    }

    @Override
    public void onBondLost(BluetoothPeripheral peripheral) {
      super.onBondLost(peripheral);
    }

    @Override
    public void onReadRemoteRssi(BluetoothPeripheral peripheral, int rssi, int status) {
      super.onReadRemoteRssi(peripheral, rssi, status);
    }

    @Override
    public void onMtuChanged(BluetoothPeripheral peripheral, int mtu, int status) {
      super.onMtuChanged(peripheral, mtu, status);
    }
  };
}
