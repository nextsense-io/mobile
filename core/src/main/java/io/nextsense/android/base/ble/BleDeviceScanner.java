package io.nextsense.android.base.ble;

import android.bluetooth.le.ScanResult;

import androidx.annotation.NonNull;

import com.welie.blessed.BluetoothCentralManagerCallback;
import com.welie.blessed.BluetoothPeripheral;
import com.welie.blessed.ScanFailure;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import io.nextsense.android.base.Device;
import io.nextsense.android.base.DeviceScanner;
import io.nextsense.android.base.communication.ble.BleCentralManagerProxy;
import io.nextsense.android.base.communication.ble.BluetoothStateManager;
import io.nextsense.android.base.communication.ble.ReconnectionManager;
import io.nextsense.android.base.db.CsvSink;
import io.nextsense.android.base.db.memory.MemoryCache;
import io.nextsense.android.base.devices.NextSenseDevice;
import io.nextsense.android.base.devices.NextSenseDeviceManager;
import io.nextsense.android.base.utils.RotatingFileLogger;

/**
 * Scans for devices and returns the list of {@link Device} that can be connected to.
 */
public class BleDeviceScanner implements DeviceScanner {

  private static final String TAG = BleDeviceScanner.class.getSimpleName();

  private final NextSenseDeviceManager deviceManager;
  private final BleCentralManagerProxy centralManagerProxy;
  private final BluetoothStateManager bluetoothStateManager;
  private final List<Device> devices = new ArrayList<>();
  private boolean scanningForPeripherals = false;
  private Set<String> foundPeripheralAddresses = new HashSet<>();
  private DeviceScanner.DeviceScanListener deviceScanListener;
  private DeviceScanner.PeripheralScanListener peripheralScanListener;

  private final MemoryCache memoryCache;
  private final CsvSink csvSink;
  private boolean scanning = false;

  private final BluetoothCentralManagerCallback bluetoothCentralManagerCallback =
      new BluetoothCentralManagerCallback() {
    @Override
    public void onDiscoveredPeripheral(@NonNull BluetoothPeripheral peripheral,
                                       @NonNull ScanResult scanResult) {
      if (!scanning || scanResult.getDevice() == null || scanResult.getDevice().getName() == null) {
        return;
      }
      for (String prefix : deviceManager.getValidPrefixes()) {
        if (scanResult.getDevice().getName().startsWith(prefix)) {
          if (foundPeripheralAddresses.contains(peripheral.getAddress())) {
            return;
          }
          foundPeripheralAddresses.add(peripheral.getAddress());
          RotatingFileLogger.get().logd(TAG, "Found valid device: " + scanResult.getDevice().getName());

          NextSenseDevice nextSenseDevice = deviceManager.getDeviceForName(peripheral.getName());
          if (nextSenseDevice == null) {
            return;
          }

          if (scanningForPeripherals) {
            peripheralScanListener.onNewPeripheral(peripheral);
            return;
          }

          ReconnectionManager reconnectionManager = ReconnectionManager.create(
              centralManagerProxy, bluetoothStateManager, BleDeviceScanner.this,
              BleDevice.RECONNECTION_ATTEMPTS_INTERVAL);
          Device device = Device.create(
              centralManagerProxy, bluetoothStateManager, nextSenseDevice, peripheral,
              reconnectionManager, memoryCache, csvSink);
          devices.add(device);
          deviceScanListener.onNewDevice(peripheral);
        }
      }
    }

    /**
     * Scanning failed
     *
     * @param scanFailure the status code for the scanning failure
     */
    @Override
    public void onScanFailed(@NonNull ScanFailure scanFailure) {
      ScanError deviceScanError = ScanError.UNDEFINED;
      switch (scanFailure) {
        case ALREADY_STARTED:
          // It should return a result once finished, let it continue.
          return;
        case APPLICATION_REGISTRATION_FAILED:
          deviceScanError = ScanError.PERMISSION_ERROR;
          break;
        case SCANNING_TOO_FREQUENTLY:
          // fallthrough.
        case UNKNOWN:
          // fallthrough.
        case OUT_OF_HARDWARE_RESOURCES:
          // fallthrough.
        case INTERNAL_ERROR:
          // Error in the Bluetooth stack, restart it and retry.
          deviceScanError = ScanError.INTERNAL_BT_ERROR;
          break;
        case FEATURE_UNSUPPORTED:
          // Cannot recover, show an error to the user and let him know to ask for support.
          deviceScanError = ScanError.FATAL_ERROR;
          break;
      }
      deviceScanListener.onScanError(deviceScanError);
    }
  };

  public BleDeviceScanner(NextSenseDeviceManager deviceManager,
                          BleCentralManagerProxy centralManagerProxy,
                          BluetoothStateManager bluetoothStateManager,
                          MemoryCache memoryCache, CsvSink csvSink) {
    this.deviceManager = deviceManager;
    this.centralManagerProxy = centralManagerProxy;
    this.bluetoothStateManager = bluetoothStateManager;
    this.memoryCache = memoryCache;
    this.csvSink = csvSink;
    centralManagerProxy.addGlobalListener(bluetoothCentralManagerCallback);
    RotatingFileLogger.get().logd(TAG, "Initialized DeviceScanner");
  }

  @Override
  public void close() {
    centralManagerProxy.removeGlobalListener(bluetoothCentralManagerCallback);
  }

  /**
   * Returns the list of valid devices that are detected.
   */
  @Override
  public void findDevices(DeviceScanner.DeviceScanListener deviceScanListener) {
    scanningForPeripherals = false;
    this.deviceScanListener = deviceScanListener;
    this.devices.clear();
    RotatingFileLogger.get().logd(TAG, "Finding Bluetooth devices...");
    centralManagerProxy.getCentralManager().stopScan();
    centralManagerProxy.getCentralManager()
        .scanForPeripheralsWithNames(deviceManager.getValidPrefixes().toArray(new String[0]));
    scanning = true;
  }

  /**
   * Returns the list of valid peripherals that are detected.
   */
  @Override
  public void findPeripherals(DeviceScanner.PeripheralScanListener peripheralScanListener) {
    scanningForPeripherals = true;
    this.peripheralScanListener = peripheralScanListener;
    RotatingFileLogger.get().logd(TAG, "Finding Bluetooth peripherals...");
    centralManagerProxy.getCentralManager().stopScan();
    centralManagerProxy.getCentralManager()
        .scanForPeripheralsWithNames(deviceManager.getValidPrefixes().toArray(new String[0]));
    scanning = true;
  }

  public List<Device> getDiscoveredDevices() {
    return devices;
  }

  /**
   * Stops finding devices if it was currently running.
   */
  @Override
  public void stopFinding() {
    scanning = false;
    centralManagerProxy.getCentralManager().stopScan();
    foundPeripheralAddresses = new HashSet<>();
  }
}
