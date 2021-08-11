package io.nextsense.android.base;

import android.bluetooth.le.ScanResult;
import androidx.annotation.NonNull;

import com.welie.blessed.BluetoothCentralManagerCallback;
import com.welie.blessed.BluetoothPeripheral;
import com.welie.blessed.ScanFailure;

import io.nextsense.android.base.communication.ble.BleCentralManagerProxy;
import io.nextsense.android.base.devices.NextSenseDevice;
import io.nextsense.android.base.devices.NextSenseDeviceManager;
import io.nextsense.android.base.utils.Util;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import static io.nextsense.android.base.utils.Util.logd;

/**
 * Scans for devices and returns the list of {@link Device} that can be connected to.
 */
public class DeviceScanner {

  /**
   * Callbacks for scanning devices.
   */
  public interface DeviceScanListener {

    enum ScanError {
      // Placeholder if reason is not assigned yet.
      UNDEFINED,
      // Bluetooth is not enabled, scan can't be completed.
      BT_DISABLED,
      // Internal error in the Android Bluetooth stack. Should try to restart it.
      INTERNAL_BT_ERROR,
      // Permission not granted. Ask the user again.
      PERMISSION_ERROR,
      // Cannot scan due to a config issue, should report the issue for further debugging.
      FATAL_ERROR
    }

    /**
     * Called when a new {@link Device} is found.
     * @param device found
     */
    void onNewDevice(Device device);

    /**
     * Called if there is an error while scanning.
     * @param scanError the cause of the error
     */
    void onScanError(ScanError scanError);
  }

  private static final String TAG = DeviceScanner.class.getSimpleName();

  private final NextSenseDeviceManager deviceManager;
  private final BleCentralManagerProxy centralManagerProxy;
  private final List<Device> devices = new ArrayList<>();
  private Set<String> foundPeripheralAddresses = new HashSet<>();
  private DeviceScanListener deviceScanListener;

  private final BluetoothCentralManagerCallback bluetoothCentralManagerCallback =
      new BluetoothCentralManagerCallback() {
    @Override
    public void onDiscoveredPeripheral(@NonNull BluetoothPeripheral peripheral,
                                       @NonNull ScanResult scanResult) {
      for (String prefix : deviceManager.getValidPrefixes()) {
        if (scanResult.getDevice().getName().startsWith(prefix)) {
          if (foundPeripheralAddresses.contains(peripheral.getAddress())) {
            return;
          }
          foundPeripheralAddresses.add(peripheral.getAddress());
          logd(TAG, "Found valid device: " + scanResult.getDevice().getName());

          NextSenseDevice nextSenseDevice = deviceManager.getDeviceForName(peripheral.getName());
          if (nextSenseDevice == null) {
            return;
          }
          Device device = new Device(centralManagerProxy, nextSenseDevice, peripheral);
          devices.add(device);
          deviceScanListener.onNewDevice(device);
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
      DeviceScanListener.ScanError deviceScanError = DeviceScanListener.ScanError.UNDEFINED;
      switch (scanFailure) {
        case ALREADY_STARTED:
          // It should return a result once finished, let it continue.
          return;
        case APPLICATION_REGISTRATION_FAILED:
          deviceScanError = DeviceScanListener.ScanError.PERMISSION_ERROR;
          break;
        case SCANNING_TOO_FREQUENTLY:
          // fallthrough.
        case UNKNOWN:
          // fallthrough.
        case OUT_OF_HARDWARE_RESOURCES:
          // fallthrough.
        case INTERNAL_ERROR:
          // Error in the Bluetooth stack, restart it and retry.
          deviceScanError = DeviceScanListener.ScanError.INTERNAL_BT_ERROR;
          break;
        case FEATURE_UNSUPPORTED:
          // Cannot recover, show an error to the user and let him know to ask for support.
          deviceScanError = DeviceScanListener.ScanError.FATAL_ERROR;
          break;
      }
      deviceScanListener.onScanError(deviceScanError);
    }
  };

  public DeviceScanner(NextSenseDeviceManager deviceManager,
                       BleCentralManagerProxy centralManagerProxy) {
    this.deviceManager = deviceManager;
    this.centralManagerProxy = centralManagerProxy;
    centralManagerProxy.addGlobalListener(bluetoothCentralManagerCallback);
    Util.logd(TAG, "Initialized DeviceScanner");
  }

  public void close() {
    centralManagerProxy.removeGlobalListener(bluetoothCentralManagerCallback);
  }

  /**
   * Returns the list of valid devices that are detected.
   */
  public void findDevices(DeviceScanListener deviceScanListener) {
    this.deviceScanListener = deviceScanListener;
    this.devices.clear();
    Util.logd(TAG, "Finding devices...");
    centralManagerProxy.getCentralManager()
        .scanForPeripheralsWithNames(deviceManager.getValidPrefixes().toArray(new String[0]));
  }

  public List<Device> getDiscoveredDevices() {
    return devices;
  }

  /**
   * Stops finding devices if it was currently running.
   */
  public void stopFindingDevices() {
    centralManagerProxy.getCentralManager().stopScan();
    foundPeripheralAddresses = new HashSet<>();
  }
}
