package io.nextsense.android.base.communication.ble;

import com.welie.blessed.BluetoothPeripheral;
import com.welie.blessed.BluetoothPeripheralCallback;

import java.time.Duration;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

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
  private final AtomicBoolean reconnecting = new AtomicBoolean(false);
  private final Duration attemptInterval;
  private ScheduledExecutorService reconnectionExecutor = Executors.newSingleThreadScheduledExecutor();
  private BluetoothPeripheral btPeripheral;
  private BluetoothPeripheralCallback callback;
  private ScheduledFuture<?> reconnectionsFuture;

  public static ReconnectionManager create(BleCentralManagerProxy centralManagerProxy,
                                           Duration attemptInterval) {
    return new ReconnectionManager(centralManagerProxy, attemptInterval);
  }

  private ReconnectionManager(BleCentralManagerProxy centralManagerProxy, Duration attemptInterval) {
    this.centralManagerProxy = centralManagerProxy;
    this.attemptInterval = attemptInterval;
  }

  public void startReconnecting(BluetoothPeripheral btPeripheral,
                                BluetoothPeripheralCallback callback) {
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
    Util.logd(TAG, "Stopped trying to reconnect.");
  }

  public boolean isReconnecting() {
    return reconnecting.get();
  }

  private void reconnect() {
    Util.logd(TAG, "Starting reconnection attempt.");
    centralManagerProxy.getCentralManager().connectPeripheral(
        btPeripheral, callback);
  }
}
