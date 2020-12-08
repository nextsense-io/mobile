package io.nextsense.android.base.communication.ble;

import android.app.Application;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.bluetooth.le.BluetoothLeScanner;
import android.bluetooth.le.ScanCallback;
import android.bluetooth.le.ScanResult;
import android.content.Context;

import java.time.Duration;
import java.util.List;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

import static io.nextsense.android.base.Util.Logd;
import static java.util.concurrent.Executors.newSingleThreadScheduledExecutor;

/**
 * Assumes that COARSE_LOCATION permission is granted already.
 * If BLE is disabled, it will not return any results.
 */
public class BleScanner {

  private static final String TAG = BleScanner.class.getSimpleName();

  public interface BleResultsListener {
    void onNewDevice(BluetoothDevice device);
  }

  private final Application application;
  private final ScheduledExecutorService scheduler = newSingleThreadScheduledExecutor();
  private final AtomicBoolean scanning = new AtomicBoolean(/*initialValue=*/false);
  private BluetoothAdapter btAdapter;
  private BluetoothLeScanner bleScanner;
  private BleResultsListener bleResultsListener;
  private List<String> devicePrefixesFilter;
  private ScheduledFuture<?> cancelTaskFuture = null;

  // Device scan callback.
  private ScanCallback leScanCallback = new ScanCallback() {
    @Override
    public void onScanResult(int callbackType, ScanResult result) {
      for (String prefix : devicePrefixesFilter) {
        if (result.getDevice().getName().startsWith(prefix)) {
          Logd(TAG, "Found valid device: " + result.getDevice().getName());
          bleResultsListener.onNewDevice(result.getDevice());
        }
      }
    }
  };

  public BleScanner(Application application) {
    this.application = application;
  }

  public void init(List<String> devicePrefixesFilter) {
    BluetoothManager btManager =
        (BluetoothManager)application.getSystemService(Context.BLUETOOTH_SERVICE);
    btAdapter = btManager.getAdapter();
    bleScanner = btAdapter.getBluetoothLeScanner();
    this.devicePrefixesFilter = devicePrefixesFilter;
  }

  /**
   * Starts scanning and returns the results in the <code>resultsListener</code>. If a scan was
   * already running, resets the <code>timeout</code>.
   * @param resultsListener will be called with valid devices
   * @return true if scan is started, false if it could not
   */
  public boolean startScanning(BleResultsListener resultsListener, Duration timeout) {
    Logd(TAG, "starting BLE scan");
    if (!btAdapter.isEnabled()) {
      return false;
    }
    bleResultsListener = resultsListener;
    if (cancelTaskFuture != null && !cancelTaskFuture.isDone()) {
      cancelTaskFuture.cancel(/*mayInterruptIfRunning=*/true);
    }
    cancelTaskFuture =
        scheduler.schedule(this::stopScanning, timeout.toMillis(), TimeUnit.MILLISECONDS);
    if (scanning.get()) {
      return true;
    }
    bleScanner.startScan(leScanCallback);
    return true;
  }

  public void stopScanning() {
    Logd(TAG, "stopping BLE scan");
    bleScanner.stopScan(leScanCallback);
  }
}