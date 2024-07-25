package io.nextsense.android.base.emulated;

import io.nextsense.android.base.DeviceScanner;
import io.nextsense.android.base.utils.RotatingFileLogger;

public class EmulatedDeviceScanner implements DeviceScanner {

  private static final String TAG = EmulatedDeviceScanner.class.getSimpleName();

  public EmulatedDeviceScanner() {
    RotatingFileLogger.get().logd(TAG, "Initialized EmulatedDeviceScanner");
  }

  @Override
  public void close() { }

  @Override
  public void findDevices(DeviceScanner.DeviceScanListener deviceScanListener) {}

  @Override
  public void findDevices(DeviceScanner.DeviceScanListener deviceScanListener, String suffix) {}

  @Override
  public void findPeripherals(DeviceScanner.PeripheralScanListener peripheralScanListener) {}

  @Override
  public void findPeripherals(DeviceScanner.PeripheralScanListener peripheralScanListener, String suffix) {}

  @Override
  public void stopFinding() { }
}
