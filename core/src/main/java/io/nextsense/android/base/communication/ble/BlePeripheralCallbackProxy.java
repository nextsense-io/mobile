package io.nextsense.android.base.communication.ble;

import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.util.ArraySet;
import android.util.Log;

import com.welie.blessed.BluetoothPeripheral;
import com.welie.blessed.BluetoothPeripheralCallback;
import com.welie.blessed.GattStatus;
import com.welie.blessed.PhyType;

import org.jetbrains.annotations.NotNull;

import java.util.Set;

/**
 * Created by Eric Bouchard on 7/12/2021.
 */
public class BlePeripheralCallbackProxy {

  private final Set<BluetoothPeripheralCallback> componentCallbacks = new ArraySet<>();

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
      for (BluetoothPeripheralCallback callback : componentCallbacks) {
        callback.onCharacteristicUpdate(peripheral, value, characteristic, status);
      }
    }

    @Override
    public void onCharacteristicWrite(
        @NotNull BluetoothPeripheral peripheral, @NotNull byte[] value,
        @NotNull BluetoothGattCharacteristic characteristic, @NotNull GattStatus status) {
      for (BluetoothPeripheralCallback callback : componentCallbacks) {
        callback.onCharacteristicWrite(peripheral, value, characteristic, status);
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
