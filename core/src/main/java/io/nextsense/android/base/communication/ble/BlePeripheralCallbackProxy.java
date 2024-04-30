package io.nextsense.android.base.communication.ble;

import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.util.ArraySet;
import androidx.annotation.NonNull;

import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;
import com.google.common.util.concurrent.SettableFuture;
import com.welie.blessed.BluetoothPeripheral;
import com.welie.blessed.BluetoothPeripheralCallback;
import com.welie.blessed.GattStatus;
import com.welie.blessed.PhyType;
import com.welie.blessed.WriteType;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;

/**
 * Proxies access to the BluetoothPeripheralCallback object so that multiple objects can listens to
 * the events that are relevant to them.
 * Also provides a few convenience methods to do Bluetooth operations synchronously using futures.
 */
public class BlePeripheralCallbackProxy {
  private static final String TAG = BlePeripheralCallbackProxy.class.getSimpleName();

  private final Set<BluetoothPeripheralCallback> componentCallbacks = new ArraySet<>();
  private final Map<String, SettableFuture<byte[]>> writeFutures = new HashMap<>();
  private final Map<String, SettableFuture<byte[]>> readFutures = new HashMap<>();
  private final Map<String, SettableFuture<Integer>> rssiFutures = new HashMap<>();

  /**
   * Gets the main device callback that should be set in the Bluetooth stack.
   */
  public BluetoothPeripheralCallback getMainCallback() {
    return deviceCallback;
  }

  public void addPeripheralCallbackListener(BluetoothPeripheralCallback callback) {
    componentCallbacks.add(callback);
  }

  public void removePeripheralCallbackListener(BluetoothPeripheralCallback callback) {
    componentCallbacks.remove(callback);
  }

  /**
   * Read a characteristic for a peripheral and return a Future that will be completed when it is
   * confirmed by the Android stack.
   */
  public synchronized ListenableFuture<byte[]> readCharacteristic(
      BluetoothPeripheral peripheral, BluetoothGattCharacteristic characteristic) {
    if (readFutures.get(peripheral.getAddress()) != null &&
        !readFutures.get(peripheral.getAddress()).isDone()) {
      // Should call this function one by one for a peripheral as it is sync.
      return Futures.immediateCancelledFuture();
    }
    SettableFuture<byte[]> readFuture = SettableFuture.create();
    readFutures.put(peripheral.getAddress(), readFuture);
    peripheral.readCharacteristic(characteristic);
    return readFuture;
  }

  /**
   * Read RSSI of a peripheral and return a Future that will be completed when it is confirmed by
   * the Android stack.
   */
  public synchronized ListenableFuture<Integer> readRSSI(BluetoothPeripheral peripheral) {
    if (rssiFutures.get(peripheral.getAddress()) != null &&
        !rssiFutures.get(peripheral.getAddress()).isDone()) {
      // Should call this function one by one for a peripheral as it is sync.
      return Futures.immediateCancelledFuture();
    }
    boolean rssiRead = peripheral.readRemoteRssi();
    if (!rssiRead) {
      return Futures.immediateFailedFuture(new BluetoothException("Failed to read RSSI"));
    }
    SettableFuture<Integer> rssiFuture = SettableFuture.create();
    rssiFutures.put(peripheral.getAddress(), rssiFuture);
    return rssiFuture;
  }

  public synchronized void cancelReadCharacteristic(
      BluetoothPeripheral peripheral, BluetoothGattCharacteristic characteristic) {
    if (readFutures.get(peripheral.getAddress()) != null &&
        !readFutures.get(peripheral.getAddress()).isDone()) {
      // Should call this function one by one for a peripheral as it is sync.
      readFutures.get(peripheral.getAddress()).cancel(true);
    }
  }

  /**
   * Write a characteristic for a peripheral and return a Future that will be completed when it is
   * confirmed by the Android stack.
   */
  public synchronized ListenableFuture<byte[]> writeCharacteristic(BluetoothPeripheral peripheral,
      BluetoothGattCharacteristic characteristic, byte[] value, WriteType writeType) {
    if (writeFutures.get(peripheral.getAddress()) != null &&
        !writeFutures.get(peripheral.getAddress()).isDone()) {
      // Should call this function one by one for a peripheral as it is sync.
      writeFutures.get(peripheral.getAddress()).cancel(true);
    }
    SettableFuture<byte[]> writeFuture = SettableFuture.create();
    writeFutures.put(peripheral.getAddress(), writeFuture);
    boolean writeDone = peripheral.writeCharacteristic(
        characteristic, value, writeType);
    if (!writeDone) {
      return Futures.immediateFailedFuture(new BluetoothException(
          "Failed to write to characteristic " + characteristic.getUuid()));
    }
    // TODO(eric): Remove this once the Android stack is fixed.
    return Futures.immediateFuture(value);
    // return writeFuture;
  }

  private final BluetoothPeripheralCallback deviceCallback = new BluetoothPeripheralCallback() {
    @Override
    public void onServicesDiscovered(@NonNull BluetoothPeripheral peripheral) {
      for (BluetoothPeripheralCallback callback : componentCallbacks) {
        callback.onServicesDiscovered(peripheral);
      }
    }

    @Override
    public void onNotificationStateUpdate(
        @NonNull BluetoothPeripheral peripheral,
        @NonNull BluetoothGattCharacteristic characteristic, @NonNull GattStatus status) {
      for (BluetoothPeripheralCallback callback : componentCallbacks) {
        callback.onNotificationStateUpdate(peripheral, characteristic, status);
      }
    }

    @Override
    public void onCharacteristicUpdate(
        @NonNull BluetoothPeripheral peripheral, @NonNull byte[] value,
        @NonNull BluetoothGattCharacteristic characteristic, @NonNull GattStatus status) {
      // Copy the values for thread-safety, they could be overwritten in the gatt object before
      // processing is finished.
      final byte[] valueCopy = new byte[value.length];
      System.arraycopy(value, 0, valueCopy, 0, value.length);

      SettableFuture<byte[]> readFuture = readFutures.get(peripheral.getAddress());
      if (readFuture != null && !readFuture.isDone()) {
        // Return a response on the future.
        if (status == GattStatus.SUCCESS) {
          readFuture.set(valueCopy);
        } else {
          readFuture.setException(
              new BluetoothException("Failed to read with status " + status));
        }
      } else {
        // Use the async callback instead.
        for (BluetoothPeripheralCallback callback : componentCallbacks) {
          callback.onCharacteristicUpdate(peripheral, valueCopy, characteristic, status);
        }
      }
    }

    @Override
    public void onCharacteristicWrite(
        @NonNull BluetoothPeripheral peripheral, @NonNull byte[] value,
        @NonNull BluetoothGattCharacteristic characteristic, @NonNull GattStatus status) {
      SettableFuture<byte[]> writeFuture = writeFutures.get(peripheral.getAddress());
      if (writeFuture != null && !writeFuture.isDone()) {
        // Return a response on the future.
        if (status == GattStatus.SUCCESS) {
          writeFuture.set(value);
        } else {
          writeFuture.setException(
              new BluetoothException("Failed to write with status " + status));
        }
      } else {
        // Use the async callback instead.
        for (BluetoothPeripheralCallback callback : componentCallbacks) {
          callback.onCharacteristicWrite(peripheral, value, characteristic, status);
        }
      }
    }

    @Override
    public void onDescriptorRead(
        @NonNull BluetoothPeripheral peripheral, @NonNull byte[] value,
        @NonNull BluetoothGattDescriptor descriptor, @NonNull GattStatus status) {
      for (BluetoothPeripheralCallback callback : componentCallbacks) {
        callback.onDescriptorRead(peripheral, value, descriptor, status);
      }
    }

    @Override
    public void onDescriptorWrite(
        @NonNull BluetoothPeripheral peripheral, @NonNull byte[] value,
        @NonNull BluetoothGattDescriptor descriptor, @NonNull GattStatus status) {
      for (BluetoothPeripheralCallback callback : componentCallbacks) {
        callback.onDescriptorWrite(peripheral, value, descriptor, status);
      }
    }

    @Override
    public void onBondingStarted(@NonNull BluetoothPeripheral peripheral) {
      for (BluetoothPeripheralCallback callback : componentCallbacks) {
        callback.onBondingStarted(peripheral);
      }
    }

    @Override
    public void onBondingSucceeded(@NonNull BluetoothPeripheral peripheral) {
      for (BluetoothPeripheralCallback callback : componentCallbacks) {
        callback.onBondingSucceeded(peripheral);
      }
    }

    @Override
    public void onBondingFailed(@NonNull BluetoothPeripheral peripheral) {
      for (BluetoothPeripheralCallback callback : componentCallbacks) {
        callback.onBondingFailed(peripheral);
      }
    }

    @Override
    public void onBondLost(@NonNull BluetoothPeripheral peripheral) {
      for (BluetoothPeripheralCallback callback : componentCallbacks) {
        callback.onBondLost(peripheral);
      }
    }

    @Override
    public void onReadRemoteRssi(
        @NonNull BluetoothPeripheral peripheral, int rssi, @NonNull GattStatus status) {
      SettableFuture<Integer> rssiFuture = rssiFutures.get(peripheral.getAddress());
      if (rssiFuture != null && !rssiFuture.isDone()) {
        // Return a response on the future.
        if (status == GattStatus.SUCCESS) {
          rssiFuture.set(rssi);
        } else {
          rssiFuture.setException(
              new BluetoothException("Failed to read RSSI with status " + status));
        }
      } else {
        for (BluetoothPeripheralCallback callback : componentCallbacks) {
          callback.onReadRemoteRssi(peripheral, rssi, status);
        }
      }
    }

    @Override
    public void onMtuChanged(
        @NonNull BluetoothPeripheral peripheral, int mtu, @NonNull GattStatus status) {
      for (BluetoothPeripheralCallback callback : componentCallbacks) {
        callback.onMtuChanged(peripheral, mtu, status);
      }
    }

    @Override
    public void onPhyUpdate(
        @NonNull BluetoothPeripheral peripheral, @NonNull PhyType txPhy, @NonNull PhyType rxPhy,
        @NonNull GattStatus status) {
      for (BluetoothPeripheralCallback callback : componentCallbacks) {
        callback.onPhyUpdate(peripheral, txPhy, rxPhy, status);
      }
    }

    @Override
    public void onConnectionUpdated(
        @NonNull BluetoothPeripheral peripheral, int interval, int latency, int timeout,
        @NonNull GattStatus status) {
      for (BluetoothPeripheralCallback callback : componentCallbacks) {
        callback.onConnectionUpdated(peripheral, interval, latency, timeout, status);
      }
    }
  };
}
