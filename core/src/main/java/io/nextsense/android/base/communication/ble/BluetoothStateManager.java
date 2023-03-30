package io.nextsense.android.base.communication.ble;

import static android.content.Context.BLUETOOTH_SERVICE;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;

import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.atomic.AtomicReference;

import io.nextsense.android.base.utils.RotatingFileLogger;

/***
 * Listens to the Android Bluetooth state and notify listeners of state changes.
 */
public class BluetoothStateManager {

  public enum AdapterState {
    ON,
    OFF,
    UNKNOWN
  }

  public interface StateChangeListener {
    void onChange(AdapterState newState);
  }

  private static final String TAG = BluetoothStateManager.class.getSimpleName();

  private final Context context;
  private final AtomicReference<AdapterState> adapterState =
      new AtomicReference<>(AdapterState.UNKNOWN);
  private final Set<StateChangeListener> onStateChangeListeners = new HashSet<>();

  private BluetoothStateManager(Context context) {
    this.context = context;
    init();
  }

  public static BluetoothStateManager create(Context context) {
    return new BluetoothStateManager(context);
  }

  public void init() {
    BluetoothManager bluetoothManager =
        (BluetoothManager) context.getSystemService(BLUETOOTH_SERVICE);
    updateState(bluetoothManager.getAdapter().getState());
    context.registerReceiver(bleStateReceiver,
        new IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED));
  }

  public void dispose() {
    context.unregisterReceiver(bleStateReceiver);
    adapterState.set(AdapterState.UNKNOWN);
  }

  public void addStateChangeListener(StateChangeListener listener) {
    onStateChangeListeners.add(listener);
  }

  public void removeStateChangeListener(StateChangeListener listener) {
    onStateChangeListeners.remove(listener);
  }

  public AdapterState getAdapterState() {
    return adapterState.get();
  }

  private void updateState(int state) {
    if (state == BluetoothAdapter.STATE_ON) {
      adapterState.set(AdapterState.ON);
    } else if (state == BluetoothAdapter.STATE_OFF) {
      adapterState.set(AdapterState.OFF);
    }
    RotatingFileLogger.get().logd(TAG, "Bluetooth adapter state is " + adapterState.get().name());
    notifyListeners();
  }

  private void notifyListeners() {
    for (StateChangeListener listener : onStateChangeListeners) {
      listener.onChange(adapterState.get());
    }
  }

  private final BroadcastReceiver bleStateReceiver = new BroadcastReceiver() {
    public void onReceive (Context context, Intent intent) {
      String action = intent.getAction();
      if (BluetoothAdapter.ACTION_STATE_CHANGED.equals(action)) {
        int intentAdapterState = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, -1);
        updateState(intentAdapterState);
      }
    }
  };
}
