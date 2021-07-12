package io.nextsense.android.base.devices;

import com.welie.blessed.BluetoothPeripheral;

import io.nextsense.android.base.DeviceMode;

/**
 *
 */
public class H15Device extends BaseNextSenseDevice implements NextSenseDevice {

  public static final String BLUETOOTH_PREFIX = "Softy";

  private static final int TARGET_MTU = 23;

  @Override
  public int getTargetMTU() {
    return TARGET_MTU;
  }

  @Override
  public void connect(BluetoothPeripheral peripheral) {
    // H1 Device specific connection logic.
  }

  @Override
  public void disconnect(BluetoothPeripheral peripheral) {

  }

  @Override
  public void changeMode(DeviceMode deviceMode) {

  }
}

