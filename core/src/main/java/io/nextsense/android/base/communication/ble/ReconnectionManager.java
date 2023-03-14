package io.nextsense.android.base.communication.ble;

import android.util.Log;

import com.welie.blessed.BluetoothPeripheral;
import com.welie.blessed.BluetoothPeripheralCallback;

import java.time.Duration;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

import io.nextsense.android.base.DeviceScanner;
import io.nextsense.android.base.utils.Util;

/**
 * Manages the reconnection trigger and attempts.
 *
 * If the device is connected manually and this tries to connect again before it can be stopped,
 * it will be a no-op so it is not an issue.
 */
public class ReconnectionManager {

  private static final String TAG = ReconnectionManager.class.getSimpleName();

  private final BleCentralManagerProxy centralManagerProxy;
  private final BluetoothStateManager bluetoothStateManager;
  private final DeviceScanner deviceScanner;
  private final AtomicBoolean reconnecting = new AtomicBoolean(false);
  private final Duration attemptInterval;
  private ScheduledExecutorService reconnectionExecutor;
  private BluetoothPeripheral btPeripheral;
  private BluetoothPeripheralCallback callback;
  private ScheduledFuture<?> reconnectionsFuture;

  public static ReconnectionManager create(BleCentralManagerProxy centralManagerProxy,
                                           BluetoothStateManager bluetoothStateManager,
                                           DeviceScanner deviceScanner,
                                           Duration attemptInterval) {
    return new ReconnectionManager(
        centralManagerProxy, bluetoothStateManager, deviceScanner, attemptInterval);
  }

  private ReconnectionManager(
      BleCentralManagerProxy centralManagerProxy, BluetoothStateManager bluetoothStateManager,
      DeviceScanner deviceScanner, Duration attemptInterval) {
    this.centralManagerProxy = centralManagerProxy;
    this.bluetoothStateManager = bluetoothStateManager;
    this.deviceScanner = deviceScanner;
    this.attemptInterval = attemptInterval;
  }

  public void startReconnecting(BluetoothPeripheral btPeripheral,
                                BluetoothPeripheralCallback callback) {
    if (bluetoothStateManager.getAdapterState().equals(BluetoothStateManager.AdapterState.OFF)) {
      Log.i(TAG, "Bluetooth is OFF, don't try to auto reconnect.");
      return;
    }
    Util.logd(TAG, "Starting trying to reconnect.");
    this.btPeripheral = btPeripheral;
    this.callback = callback;
    reconnectionExecutor = Executors.newSingleThreadScheduledExecutor();
    reconnecting.set(true);
    reconnectionsFuture = reconnectionExecutor.scheduleAtFixedRate(() -> {
      if (reconnecting.get()) {
        reconnect();
      }
    }, attemptInterval.toMillis(), attemptInterval.toMillis(), TimeUnit.MILLISECONDS);
  }

  public void stopReconnecting() {
    reconnecting.set(false);
    reconnectionsFuture.cancel(true);
    reconnectionExecutor.shutdown();
    deviceScanner.stopFinding();
    Util.logd(TAG, "Stopped trying to reconnect.");
  }

  public boolean isReconnecting() {
    return reconnecting.get();
  }

  private void reconnect() {
    Util.logd(TAG, "Starting reconnection attempt.");
    if (bluetoothStateManager.getAdapterState().equals(BluetoothStateManager.AdapterState.OFF)) {
      Log.i(TAG, "Trying to reconnect but Bluetooth is OFF.");
      return;
    }
    if (centralManagerProxy.getCentralManager().getConnectedPeripherals().isEmpty()) {
      deviceScanner.findPeripherals(new DeviceScanner.PeripheralScanListener() {
        @Override
        public void onNewPeripheral(BluetoothPeripheral peripheral) {
          if (peripheral.getName().equals(btPeripheral.getName())) {
            Log.i(TAG, "Device found, trying to reconnect.");
            deviceScanner.stopFinding();
            centralManagerProxy.getCentralManager().connectPeripheral(btPeripheral, callback);
          }
        }

        @Override
        public void onScanError(ScanError scanError) {
          Log.w(TAG, "Scan error: " + scanError.toString());
        }
      });
    } else {
      Log.w(TAG, "Trying to reconnect when there is already a connected device.");
      stopReconnecting();
    }
  }
}
