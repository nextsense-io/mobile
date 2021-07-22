package io.nextsense.android.base.communication.ble;

import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.util.ArraySet;

import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;
import com.google.common.util.concurrent.SettableFuture;
import com.welie.blessed.BluetoothPeripheral;
import com.welie.blessed.BluetoothPeripheralCallback;
import com.welie.blessed.GattStatus;
import com.welie.blessed.PhyType;
import com.welie.blessed.WriteType;

import org.jetbrains.annotations.NotNull;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;

/**
 * Proxies access to the BluetoothPeripheralCallback object so that multiple objects can listens to
 * the events that are relevant to them.
 *
 * Also provides a few convenience methods to do Bluetooth operations synchronously using futures.
 */
public class BlePeripheralCallbackProxy {

  private final Set<BluetoothPeripheralCallback> componentCallbacks = new ArraySet<>();
  private final Map<String, SettableFuture<byte[]>> writeFutures = new HashMap<>();
  private final Map<String, SettableFuture<byte[]>> readFutures = new HashMap<>();

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
   * Write a characteristic for a peripheral and return a Future that will be completed when it is
   * confirmed by the Android stack. This implies that it is of type WRITE_WITH_RESPONSE.
   */
  public synchronized ListenableFuture<byte[]> writeCharacteristic(
      BluetoothPeripheral peripheral, BluetoothGattCharacteristic characteristic, byte[] value) {
    if (writeFutures.get(peripheral.getAddress()) != null &&
        !writeFutures.get(peripheral.getAddress()).isDone()) {
      // Should call this function one by one for a peripheral as it is sync.
      return Futures.immediateCancelledFuture();
    }
    SettableFuture<byte[]> writeFuture = SettableFuture.create();
    writeFutures.put(peripheral.getAddress(), writeFuture);
    boolean writeDone = peripheral.writeCharacteristic(characteristic, value, WriteType.WITH_RESPONSE);
    if (!writeDone) {
      return Futures.immediateFailedFuture(new BluetoothException(
          "Failed to write to characteristic " + characteristic.getUuid()));
    }
    return writeFuture;
  }


  private final BluetoothPeripheralCallback deviceCallback = new BluetoothPeripheralCallback() {
    @Override
    public void onServicesDiscovered(@NotNull BluetoothPeripheral peripheral) {
      for (BluetoothPeripheralCallback callback : componentCallbacks) {
        callback.onServicesDiscovered(peripheral);
      }
    }

    @Override
    public void onNotificationStateUpdate(
        @NotNull BluetoothPeripheral peripheral,
        @NotNull BluetoothGattCharacteristic characteristic, @NotNull GattStatus status) {
      for (BluetoothPeripheralCallback callback : componentCallbacks) {
        callback.onNotificationStateUpdate(peripheral, characteristic, status);
      }
    }

    @Override
    public void onCharacteristicUpdate(
        @NotNull BluetoothPeripheral peripheral, @NotNull byte[] value,
        @NotNull BluetoothGattCharacteristic characteristic, @NotNull GattStatus status) {
      SettableFuture<byte[]> readFuture = readFutures.get(peripheral.getAddress());
      if (readFuture != null && !readFuture.isDone()) {
        // Return a response on the future.
        if (status == GattStatus.SUCCESS) {
          readFuture.set(value);
        } else {
          readFuture.setException(
              new BluetoothException("Failed to read with status " + status.toString()));
        }
      } else {
        // Use the async callback instead.
        for (BluetoothPeripheralCallback callback : componentCallbacks) {
          callback.onCharacteristicUpdate(peripheral, value, characteristic, status);
        }
      }
    }

    @Override
    public void onCharacteristicWrite(
        @NotNull BluetoothPeripheral peripheral, @NotNull byte[] value,
        @NotNull BluetoothGattCharacteristic characteristic, @NotNull GattStatus status) {
      SettableFuture<byte[]> writeFuture = writeFutures.get(peripheral.getAddress());
      if (writeFuture != null && !writeFuture.isDone()) {
        // Return a response on the future.
        if (status == GattStatus.SUCCESS) {
          writeFuture.set(value);
        } else {
          writeFuture.setException(
              new BluetoothException("Failed to write with status " + status.toString()));
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
        @NotNull BluetoothPeripheral peripheral, @NotNull byte[] value,
        @NotNull BluetoothGattDescriptor descriptor, @NotNull GattStatus status) {
      for (BluetoothPeripheralCallback callback : componentCallbacks) {
        callback.onDescriptorRead(peripheral, value, descriptor, status);
      }
    }

    @Override
    public void onDescriptorWrite(
        @NotNull BluetoothPeripheral peripheral, @NotNull byte[] value,
        @NotNull BluetoothGattDescriptor descriptor, @NotNull GattStatus status) {
      for (BluetoothPeripheralCallback callback : componentCallbacks) {
        callback.onDescriptorWrite(peripheral, value, descriptor, status);
      }
    }

    @Override
    public void onBondingStarted(@NotNull BluetoothPeripheral peripheral) {
      for (BluetoothPeripheralCallback callback : componentCallbacks) {
        callback.onBondingStarted(peripheral);
      }
    }

    @Override
    public void onBondingSucceeded(@NotNull BluetoothPeripheral peripheral) {
      for (BluetoothPeripheralCallback callback : componentCallbacks) {
        callback.onBondingSucceeded(peripheral);
      }
    }

    @Override
    public void onBondingFailed(@NotNull BluetoothPeripheral peripheral) {
      for (BluetoothPeripheralCallback callback : componentCallbacks) {
        callback.onBondingFailed(peripheral);
      }
    }

    @Override
    public void onBondLost(@NotNull BluetoothPeripheral peripheral) {
      for (BluetoothPeripheralCallback callback : componentCallbacks) {
        callback.onBondLost(peripheral);
      }
    }

    @Override
    public void onReadRemoteRssi(
        @NotNull BluetoothPeripheral peripheral, int rssi, @NotNull GattStatus status) {
      for (BluetoothPeripheralCallback callback : componentCallbacks) {
        callback.onReadRemoteRssi(peripheral, rssi, status);
      }
    }

    @Override
    public void onMtuChanged(
        @NotNull BluetoothPeripheral peripheral, int mtu, @NotNull GattStatus status) {
      for (BluetoothPeripheralCallback callback : componentCallbacks) {
        callback.onMtuChanged(peripheral, mtu, status);
      }
    }

    @Override
    public void onPhyUpdate(
        @NotNull BluetoothPeripheral peripheral, @NotNull PhyType txPhy, @NotNull PhyType rxPhy,
        @NotNull GattStatus status) {
      for (BluetoothPeripheralCallback callback : componentCallbacks) {
        callback.onPhyUpdate(peripheral, txPhy, rxPhy, status);
      }
    }

    @Override
    public void onConnectionUpdated(
        @NotNull BluetoothPeripheral peripheral, int interval, int latency, int timeout,
        @NotNull GattStatus status) {
      for (BluetoothPeripheralCallback callback : componentCallbacks) {
        callback.onConnectionUpdated(peripheral, interval, latency, timeout, status);
      }
    }
  };
}
