package io.nextsense.android.base;


import java.util.List;

import io.nextsense.android.Config;
import io.nextsense.android.base.ble.BleDeviceManager;
import io.nextsense.android.base.ble.EmulatedDeviceManager;
import io.nextsense.android.base.data.LocalSessionManager;

/**
 * Interface to outside clients. Helps to manage the lifecycle of devices and common errors.
 */
public interface DeviceManager {

  void close();

  void findDevices(DeviceScanner.DeviceScanListener deviceScanListener);

  List<Device> getConnectedDevices();

  void stopFindingDevices(DeviceScanner.DeviceScanListener deviceScanListener);

  static DeviceManager create(DeviceScanner deviceScanner, LocalSessionManager localSessionManager) {
    if (Config.useEmulatedBle)
      return new EmulatedDeviceManager(deviceScanner, localSessionManager);

    return new BleDeviceManager(deviceScanner);
  }
}
