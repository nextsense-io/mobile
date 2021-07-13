package io.nextsense.android.base.devices;

import android.bluetooth.BluetoothGattCharacteristic;

import com.welie.blessed.BluetoothPeripheral;

import java.util.UUID;

import io.nextsense.android.base.DeviceMode;

/**
 * Created by Eric Bouchard on 12/9/2020.
 */
public abstract class BaseNextSenseDevice implements NextSenseDevice {

  protected DeviceMode deviceMode = DeviceMode.IDLE;
  protected BluetoothPeripheral peripheral;

  @Override
  public DeviceMode getDeviceMode() {
    return deviceMode;
  }

  @Override
  public void connect(BluetoothPeripheral peripheral) {

  }

  @Override
  public void disconnect(BluetoothPeripheral peripheral) {

  }

  protected void checkCharacteristic(BluetoothGattCharacteristic characteristic, UUID serviceUuid,
                                     UUID charUuid) {
    if (characteristic == null) {
      throw new UnsupportedOperationException("Cannot find the service " + serviceUuid.toString() +
          " and/or the characteristic " + charUuid + " on this device.");
    }
  }
}
