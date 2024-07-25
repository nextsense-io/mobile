package io.nextsense.android.base;

import java.util.List;
import java.util.Optional;

import io.nextsense.android.Config;
import io.nextsense.android.base.ble.BleDeviceManager;
import io.nextsense.android.base.communication.ble.BleCentralManagerProxy;
import io.nextsense.android.base.communication.ble.BluetoothStateManager;
import io.nextsense.android.base.data.LocalSessionManager;
import io.nextsense.android.base.db.CsvSink;
import io.nextsense.android.base.db.memory.MemoryCache;
import io.nextsense.android.base.devices.NextSenseDeviceManager;
import io.nextsense.android.base.emulated.EmulatedDeviceManager;

/**
 * Interface to outside clients. Helps to manage the lifecycle of devices and common errors.
 */
public interface DeviceManager {

  /**
   * Callbacks for scanning devices.
   */
  interface DeviceScanListener {

    /**
     * Called when a new {@link Device} is found.
     * @param device found
     */
    void onNewDevice(Device device);

    /**
     * Called if there is an error while scanning.
     * @param scanError the cause of the error
     */
    void onScanError(DeviceScanner.ScanError scanError);
  }

  void close();

  void findDevices(DeviceScanListener deviceScanListener);

  void findDevices(DeviceScanListener deviceScanListener, String suffix);

  List<Device> getConnectedDevices();

  void stopFindingDevices(DeviceScanListener deviceScanListener);

  Optional<Device> getDevice(String macAddress);

  static DeviceManager create(DeviceScanner deviceScanner,
                              LocalSessionManager localSessionManager,
                              BleCentralManagerProxy centralManagerProxy,
                              BluetoothStateManager bluetoothStateManager,
                              NextSenseDeviceManager nextSenseDeviceManager,
                              MemoryCache memoryCache, CsvSink csvSink) {
    if (Config.USE_EMULATED_BLE)
      return new EmulatedDeviceManager(deviceScanner, localSessionManager);

    return new BleDeviceManager(
        deviceScanner, centralManagerProxy, bluetoothStateManager, nextSenseDeviceManager,
        memoryCache, csvSink);
  }
}
