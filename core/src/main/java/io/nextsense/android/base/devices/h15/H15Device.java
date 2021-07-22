package io.nextsense.android.base.devices.h15;

import android.bluetooth.BluetoothGattCharacteristic;

import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;
import com.google.common.util.concurrent.SettableFuture;
import com.welie.blessed.BluetoothPeripheral;
import com.welie.blessed.BluetoothPeripheralCallback;
import com.welie.blessed.GattStatus;

import org.jetbrains.annotations.NotNull;

import java.util.Arrays;
import java.util.UUID;

import io.nextsense.android.base.DeviceMode;
import io.nextsense.android.base.Util;
import io.nextsense.android.base.communication.ble.BlePeripheralCallbackProxy;
import io.nextsense.android.base.communication.ble.BluetoothException;
import io.nextsense.android.base.devices.BaseNextSenseDevice;
import io.nextsense.android.base.devices.NextSenseDevice;

/**
 * Next generation single ear device prototype that was designed at Google X by Russ.
 * Does not have configuration capabilities, can only stream data when notifying is turned on.
 * Provides a single channel of EEG data.
 */
public class H15Device extends BaseNextSenseDevice implements NextSenseDevice {

  public static final String BLUETOOTH_PREFIX = "Softy";

  private static final String TAG = H15Device.class.getSimpleName();
  private static final int TARGET_MTU = 23;
  private static final UUID SERVICE_UUID = UUID.fromString("cb577fc4-7260-41f8-8216-3be734c7820a");
  private static final UUID DATA_UUID = UUID.fromString("59e33cfa-497d-4356-bb46-b87888419cb2");

  private BlePeripheralCallbackProxy blePeripheralCallbackProxy;
  private BluetoothGattCharacteristic dataCharacteristic;
  private SettableFuture<DeviceMode> deviceModeFuture;

  @Override
  public void setBluetoothPeripheralProxy(BlePeripheralCallbackProxy proxy) {
    blePeripheralCallbackProxy = proxy;
    blePeripheralCallbackProxy.addPeripheralCallbackListener(bluetoothPeripheralCallback);
  }

  @Override
  public boolean isDataCharacteristic(BluetoothGattCharacteristic characteristic) {
    return characteristic.getUuid() == dataCharacteristic.getUuid();
  }

  @Override
  public int getTargetMTU() {
    return TARGET_MTU;
  }

  @Override
  public ListenableFuture<Boolean> connect(BluetoothPeripheral peripheral) {
    // H15 Device specific connection logic.
    this.peripheral = peripheral;
    dataCharacteristic = peripheral.getCharacteristic(SERVICE_UUID, DATA_UUID);
    checkCharacteristic(dataCharacteristic, SERVICE_UUID, DATA_UUID);
    return Futures.immediateFuture(null);
  }

  @Override
  public void disconnect(BluetoothPeripheral peripheral) {
    this.peripheral = null;
    dataCharacteristic = null;
  }

  @Override
  public ListenableFuture<DeviceMode> changeMode(DeviceMode deviceMode) {
    if (this.deviceMode == deviceMode) {
      return Futures.immediateFuture(deviceMode);
    }
    switch (deviceMode) {
      case STREAMING:
        if (dataCharacteristic == null) {
          return Futures.immediateFailedFuture(
              new IllegalStateException("No characteristic to stream on."));
        }
        peripheral.setNotify(dataCharacteristic, /*enable=*/true);
        break;
      case IDLE:
        if (dataCharacteristic == null) {
          return Futures.immediateFuture(DeviceMode.IDLE);
        }
        peripheral.setNotify(dataCharacteristic, /*enable=*/false);
        break;
      default:
        return Futures.immediateFailedFuture(new UnsupportedOperationException(
            "The " + deviceMode.toString() + " is not supported on this device."));
    }
    deviceModeFuture = SettableFuture.create();
    return deviceModeFuture;
  }

  private final BluetoothPeripheralCallback bluetoothPeripheralCallback =
      new BluetoothPeripheralCallback() {
    @Override
    public void onNotificationStateUpdate(
        @NotNull BluetoothPeripheral peripheral,
        @NotNull BluetoothGattCharacteristic characteristic, @NotNull GattStatus status) {
      if (!deviceModeFuture.isDone() && isDataCharacteristic(characteristic)) {
        if (status == GattStatus.SUCCESS) {
          Util.logd(TAG, "Notification updated with success to " +
              peripheral.isNotifying(characteristic));
          if (peripheral.isNotifying(characteristic)) {
            deviceMode = DeviceMode.STREAMING;
            deviceModeFuture.set(DeviceMode.STREAMING);
          } else {
            deviceMode = DeviceMode.IDLE;
            deviceModeFuture.set(DeviceMode.IDLE);
          }
        } else {
          deviceModeFuture.setException(new BluetoothException(
              "Notification state update failed with code " + status));
        }
      }
    }

    @Override
    public void onCharacteristicUpdate(
        @NotNull BluetoothPeripheral peripheral, @NotNull byte[] value,
        @NotNull BluetoothGattCharacteristic characteristic, @NotNull GattStatus status) {
      Util.logv(TAG, "Data received: " + Arrays.toString(value));
    }
  };
}

