package io.nextsense.android.base.emulated;

import io.nextsense.android.base.DeviceScanner;
import io.nextsense.android.base.utils.Util;

public class EmulatedDeviceScanner implements DeviceScanner {

  private static final String TAG = EmulatedDeviceScanner.class.getSimpleName();

  public EmulatedDeviceScanner() {
    Util.logd(TAG, "Initialized EmulatedDeviceScanner");
  }

  @Override
  public void close() { }

  @Override
  public void findDevices(DeviceScanner.DeviceScanListener deviceScanListener) {}

  @Override
  public void stopFindingDevices() { }
}
