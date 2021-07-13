package io.nextsense.android.base.devices;

import android.bluetooth.BluetoothGattCharacteristic;

import com.google.common.util.concurrent.ListenableFuture;
import com.welie.blessed.BluetoothPeripheral;
import com.welie.blessed.BluetoothPeripheralCallback;

import io.nextsense.android.base.DeviceMode;

/**
 * Defines the interface of NextSense devices.
 */
public interface NextSenseDevice {

  // Gets the target Bluetooth MTU for this device.
  int getTargetMTU();


  BluetoothPeripheralCallback getBluetoothPeripheralCallback();

  boolean isDataCharacteristic(BluetoothGattCharacteristic characteristic);

  void connect(BluetoothPeripheral peripheral);

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
