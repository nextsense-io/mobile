package io.nextsense.android.base.devices;

import android.bluetooth.BluetoothGattCharacteristic;

import com.google.common.util.concurrent.ListenableFuture;
import com.welie.blessed.BluetoothPeripheral;

import io.nextsense.android.base.DeviceMode;
import io.nextsense.android.base.communication.ble.BlePeripheralCallbackProxy;

/**
 * Defines the interface of NextSense devices.
 */
public interface NextSenseDevice {

  // Gets the target Bluetooth MTU for this device.
  int getTargetMTU();

  // Gets the maximum number of channels that the device could have.
  int getChannelCount();

  void setBluetoothPeripheralProxy(BlePeripheralCallbackProxy proxy);

  boolean isDataCharacteristic(BluetoothGattCharacteristic characteristic);

  ListenableFuture<Boolean> connect(BluetoothPeripheral peripheral);

  void disconnect(BluetoothPeripheral peripheral);

  /**
   * Changes the {@link DeviceMode}.
   * @return true if notification is being changed, false if could not try.
   */
  ListenableFuture<DeviceMode> changeMode(DeviceMode deviceMode);

  /**
   * Returns the current {@link DeviceMode}.
   * @return DeviceMode
   */
  DeviceMode getDeviceMode();
}
