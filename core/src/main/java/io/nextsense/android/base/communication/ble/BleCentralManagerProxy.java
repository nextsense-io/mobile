package io.nextsense.android.base.communication.ble;

import android.bluetooth.le.ScanResult;
import android.content.Context;
import android.os.Handler;
import android.os.HandlerThread;
import android.util.ArraySet;
import android.util.Log;
import androidx.annotation.NonNull;

import com.welie.blessed.BluetoothCentralManager;
import com.welie.blessed.BluetoothCentralManagerCallback;
import com.welie.blessed.BluetoothPeripheral;
import com.welie.blessed.HciStatus;
import com.welie.blessed.ScanFailure;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;

import io.nextsense.android.base.utils.Util;

/**
 * Proxies access to the BluetoothCentralManager object so that multiple objects can listens to
 * the events that are relevant to them.
 */
public class BleCentralManagerProxy {

  private static final String TAG = BleCentralManagerProxy.class.getSimpleName();

  private final BluetoothCentralManager centralManager;
  private final Set<BluetoothCentralManagerCallback> globalCallbacks = new ArraySet<>();
  private final Map<String, BluetoothCentralManagerCallback> peripheralCallbacks = new HashMap<>();
  private Handler centralHandler;
  private HandlerThread centralHandlerThread;

  private final BluetoothCentralManagerCallback bluetoothCentralManagerCallback =
      new BluetoothCentralManagerCallback() {
        @Override
        public void onDiscoveredPeripheral(@NonNull BluetoothPeripheral peripheral,
                                           @NonNull ScanResult scanResult) {
          for (BluetoothCentralManagerCallback callback : globalCallbacks) {
            callback.onDiscoveredPeripheral(peripheral, scanResult);
          }
        }

        /**
         * Scanning failed
         *
         * @param scanFailure the status code for the scanning failure
         */
        @Override
        public void onScanFailed(@NonNull ScanFailure scanFailure) {
          for (BluetoothCentralManagerCallback callback : globalCallbacks) {
            callback.onScanFailed(scanFailure);
          }
        }

        @Override
        public void onConnectedPeripheral(@NonNull BluetoothPeripheral peripheral) {
          Log.d(TAG, "Connected with device " + peripheral.getName());
          for (BluetoothCentralManagerCallback callback : globalCallbacks) {
            callback.onConnectedPeripheral(peripheral);
          }
          BluetoothCentralManagerCallback callback =
              peripheralCallbacks.get(peripheral.getAddress());
          if (callback != null) {
            callback.onConnectedPeripheral(peripheral);
          }
        }

        @Override
        public void onConnectionFailed(@NonNull BluetoothPeripheral peripheral,
                                       @NonNull HciStatus status) {
          Log.w(TAG, "Connection with device " + peripheral.getName() + " failed. HCI status: " +
              status.toString());
          for (BluetoothCentralManagerCallback callback : globalCallbacks) {
            callback.onConnectionFailed(peripheral, status);
          }
          BluetoothCentralManagerCallback callback =
              peripheralCallbacks.get(peripheral.getAddress());
          if (callback != null) {
            callback.onConnectionFailed(peripheral, status);
          }
        }

        @Override
        public void onConnectingPeripheral(@NonNull BluetoothPeripheral peripheral) {
          Util.logd(TAG, "Device " + peripheral.getName() + " connecting.");
          for (BluetoothCentralManagerCallback callback : globalCallbacks) {
            callback.onConnectingPeripheral(peripheral);
          }
          BluetoothCentralManagerCallback callback =
              peripheralCallbacks.get(peripheral.getAddress());
          if (callback != null) {
            callback.onConnectingPeripheral(peripheral);
          }
        }

        @Override
        public void onDisconnectingPeripheral(@NonNull BluetoothPeripheral peripheral) {
          Util.logd(TAG, "Device " + peripheral.getName() + " disconnecting.");
          for (BluetoothCentralManagerCallback callback : globalCallbacks) {
            callback.onDisconnectingPeripheral(peripheral);
          }
          BluetoothCentralManagerCallback callback =
              peripheralCallbacks.get(peripheral.getAddress());
          if (callback != null) {
            callback.onDisconnectingPeripheral(peripheral);
          }
        }

        @Override
        public void onDisconnectedPeripheral(@NonNull BluetoothPeripheral peripheral,
                                             @NonNull HciStatus status) {
          Util.logd(TAG, "Device " + peripheral.getName() + " disconnected.");
          for (BluetoothCentralManagerCallback callback : globalCallbacks) {
            callback.onDisconnectedPeripheral(peripheral, status);
          }
          BluetoothCentralManagerCallback callback =
              peripheralCallbacks.get(peripheral.getAddress());
          if (callback != null) {
            callback.onDisconnectedPeripheral(peripheral, status);
          }
        }
      };

  public BleCentralManagerProxy(Context context) {
    startCentralHandlerThread();
    centralManager = new BluetoothCentralManager(context, bluetoothCentralManagerCallback,
        centralHandler);
  }

  public void close() {
    stopCentralHandlerThread();
  }

  public BluetoothCentralManager getCentralManager() {
    return centralManager;
  }

  public void addGlobalListener(BluetoothCentralManagerCallback bluetoothCentralManagerCallback) {
    globalCallbacks.add(bluetoothCentralManagerCallback);
  }

  public void removeGlobalListener(BluetoothCentralManagerCallback bluetoothCentralManagerCallback) {
    globalCallbacks.remove(bluetoothCentralManagerCallback);
  }

  public void addPeripheralListener(BluetoothCentralManagerCallback bluetoothCentralManagerCallback,
                                    String peripheralAddress) {
    peripheralCallbacks.put(peripheralAddress, bluetoothCentralManagerCallback);
  }

  public void removePeripheralListener(String peripheralAddress) {
    peripheralCallbacks.remove(peripheralAddress);
  }

  private void startCentralHandlerThread() {
    centralHandlerThread = new HandlerThread("centralHandlerThread");
    centralHandlerThread.start();
    centralHandler = new Handler(centralHandlerThread.getLooper());
  }

  private void stopCentralHandlerThread() {
    centralHandlerThread.quitSafely();
  }
}
