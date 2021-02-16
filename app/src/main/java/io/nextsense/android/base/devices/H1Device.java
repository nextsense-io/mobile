package io.nextsense.android.base.devices;

import android.bluetooth.BluetoothDevice;

import io.nextsense.android.base.DeviceMode;

/**
 *
 */
public class H1Device extends BaseNextSenseDevice implements NextSenseDevice {
  @Override
  public void connect(BluetoothDevice btDevice) {
    super.connect(btDevice);
    // H1 Device specific connection logic.
  }

  @Override
  public void disconnect(BluetoothDevice btDevice) {
    super.disconnect(btDevice);
  }

  @Override
  public void changeMode(DeviceMode deviceMode) {

  }
}
