package io.nextsense.android.base.devices;

import android.bluetooth.BluetoothDevice;

import io.nextsense.android.base.DeviceMode;

/**
 * Defines the interface of NextSense devices.
 */
public interface NextSenseDevice {

  void connect(BluetoothDevice btDevice);

  void disconnect(BluetoothDevice btDevice);

  void changeMode(DeviceMode deviceMode);
}
