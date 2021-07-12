package io.nextsense.android.base.devices;

import com.welie.blessed.BluetoothPeripheral;

import io.nextsense.android.base.DeviceMode;

/**
 * Defines the interface of NextSense devices.
 */
public interface NextSenseDevice {

  // Gets the target Bluetooth MTU for this device.
  int getTargetMTU();

  void connect(BluetoothPeripheral peripheral);

  void disconnect(BluetoothPeripheral peripheral);

  void changeMode(DeviceMode deviceMode);
}
