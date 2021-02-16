package io.nextsense.android.base;

import android.app.Application;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.le.ScanResult;
import android.os.Handler;
import android.os.Looper;

import com.welie.blessed.BluetoothCentral;
import com.welie.blessed.BluetoothCentralCallback;
import com.welie.blessed.BluetoothPeripheral;

import java.time.Duration;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import io.nextsense.android.base.communication.ble.BleScanner;

/**
 * Scans for devices and returns the list of {@link Device} that can be connected to.
 */
public class DeviceScanner {

  /**
   * Callbacks for scanning devices.
   */
  public interface DeviceScanListener {

    enum ScanError {
      BT_DISABLED,  // Bluetooth is not enabled, scan can't be completed.
      INTERNAL_BT_ERROR,  // Internal error in the Android Bluetooth stack. Should try to restart it.
      UNDEFINED  // Placeholder if reason is not assigned yet.
    }

    /**
     * Called when a new {@link Device} is found.
     * @param device found
     */
    void onNewDevice(Device device);

    /**
     * Called when the scan is complete.
     */
    void onScanComplete();

    /**
     * Called if there is an error while scanning.
     * @param scanError the cause of the error
     */
    void onScanError(ScanError scanError);
  }

  private static final String TAG = DeviceScanner.class.getSimpleName();
  // TODO(eric): Define real list from Device list.
  private static final List<String> DEVICE_PREFIXES = Arrays.asList("heimdallr", "H1");

  // private final BleScanner bleScanner;
  private BluetoothCentral central;
  private final List<Device> devices = new ArrayList<>();
  private DeviceScanListener deviceScanListener;

  private final BluetoothCentralCallback bluetoothCentralCallback2 = new BluetoothCentralCallback() {
    @Override
    public void onConnectedPeripheral(BluetoothPeripheral peripheral) {
      super.onConnectedPeripheral(peripheral);
    }

    @Override
    public void onConnectionFailed(BluetoothPeripheral peripheral, int status) {
      super.onConnectionFailed(peripheral, status);
    }

    @Override
    public void onDisconnectedPeripheral(BluetoothPeripheral peripheral, int status) {
      super.onDisconnectedPeripheral(peripheral, status);
    }

    @Override
    public void onDiscoveredPeripheral(BluetoothPeripheral peripheral, ScanResult scanResult) {
      super.onDiscoveredPeripheral(peripheral, scanResult);
    }

    @Override
    public void onScanFailed(int errorCode) {
      super.onScanFailed(errorCode);
    }

    @Override
    public void onBluetoothAdapterStateChanged(int state) {
      super.onBluetoothAdapterStateChanged(state);
    }
  };
  private final BluetoothCentralCallback bluetoothCentralCallback = new BluetoothCentralCallback() {
    @Override
    public void onDiscoveredPeripheral(BluetoothPeripheral peripheral, ScanResult scanResult) {
//      Device device = new Device(DeviceType.H1, scanResult.getDevice(), central);
//      devices.add(device);
//      deviceScanListener.onNewDevice(device);
    }
  };

  public DeviceScanner(Application application) {
     // bleScanner = new BleScanner(application);
     // bleScanner.init(DEVICE_PREFIXES);

     // Create BluetoothCentral and receive callbacks on the main thread
     // TODO(eric): Move to another thread.
     central = new BluetoothCentral(
         application, bluetoothCentralCallback, new Handler(Looper.getMainLooper()));
  }

  /**
   * Returns the list of valid devices that are detected.
   * timeout timeout for finding devices. 0 means no timeout.
   */
  public void findDevices(DeviceScanListener deviceScanListener, Duration timeout) {
    // this.deviceScanListener = deviceScanListener;
    // bleScanner.startScanning(bleResultsListener, timeout);
    central.scanForPeripheralsWithNames(devices.toArray(new String[0]));
  }

  /**
   * Stops finding devices if it was currently running.
   */
  public void stopFindingDevices() {
    // bleScanner.stopScanning();
    central.stopScan();
  }

  private final BleScanner.BleResultsListener bleResultsListener =
      new BleScanner.BleResultsListener() {
    @Override
    public void onNewDevice(BluetoothDevice btDevice) {
      // TODO(eric): Determine device type from name.

//      Device device = new Device(DeviceType.H1, btDevice);
//      devices.add(device);
//      deviceScanListener.onNewDevice(device);
    }

    @Override
    public void onScanComplete() {
      deviceScanListener.onScanComplete();
    }

    @Override
    public void onScanError(BleScanner.ScanError scanError) {
      DeviceScanListener.ScanError deviceScanError = DeviceScanListener.ScanError.UNDEFINED;
      switch (scanError) {
        case BT_DISABLED:
          deviceScanError = DeviceScanListener.ScanError.BT_DISABLED;
          break;
        case INTERNAL_BT_ERROR:
          deviceScanError = DeviceScanListener.ScanError.INTERNAL_BT_ERROR;
          break;
      }
      deviceScanListener.onScanError(deviceScanError);
    }
  };
}
