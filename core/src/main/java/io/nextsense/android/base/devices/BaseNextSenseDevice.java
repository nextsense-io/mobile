package io.nextsense.android.base.devices;

import androidx.annotation.Nullable;

import com.welie.blessed.BluetoothPeripheral;

/**
 * Created by Eric Bouchard on 12/9/2020.
 */
public abstract class BaseNextSenseDevice implements NextSenseDevice {

  @Override
  public void connect(BluetoothPeripheral peripheral) {

  }

  @Override
  public void disconnect(BluetoothPeripheral peripheral) {

  }
}
