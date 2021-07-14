package io.nextsense.android.base.devices;

import android.bluetooth.BluetoothGattCharacteristic;

import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;
import com.google.common.util.concurrent.SettableFuture;
import com.welie.blessed.BluetoothPeripheral;
import com.welie.blessed.BluetoothPeripheralCallback;
import com.welie.blessed.GattStatus;
import com.welie.blessed.WriteType;

import org.jetbrains.annotations.NotNull;

import java.nio.ByteBuffer;
import java.nio.IntBuffer;
import java.util.Arrays;
import java.util.UUID;

import io.nextsense.android.base.DeviceMode;
import io.nextsense.android.base.Util;
import io.nextsense.android.base.communication.ble.BluetoothException;

/**
 * First Generation device that was built at Google X with Culvert Engineering.
 * Dual-ear device with cross-ear channels. Channels 1, 2 and 5 plus the optosync on channel 7 are
 * typically enabled.
 * Provides device information queries, configuration of a few parameters and data streaming.
 */
public class H1Device extends BaseNextSenseDevice implements NextSenseDevice {

  public static final String BLUETOOTH_PREFIX = "Heimdallr";

  private static final String TAG = H1Device.class.getSimpleName();
  private static final int TARGET_MTU = 256;
  private static final int[] START_STREAMING = {0x81};
  private static final int[] STOP_STREAMING = {0x80};
  private static final UUID SERVICE_UUID = UUID.fromString("59462f12-9543-9999-12c8-58b459a2712d");
  private static final UUID DATA_UUID = UUID.fromString("5c3a659e-897e-45e1-b016-007107c96df6");
  private static final UUID VOLTAGE_UUID = UUID.fromString("5c3a659e-897e-45e1-b016-007107c96df3");
  private static final UUID WRITE_DATA_UUID =
      UUID.fromString("5c3a659e-897e-45e1-b016-007107c96df7");
  private static final UUID CONFIG_UUID = UUID.fromString("5c3a659e-897e-45e1-b016-007107c96df4");
  private static final UUID REGISTERS_UUID =
      UUID.fromString("5c3a659e-897e-45e1-b016-007107c96df5");
  private static final UUID FIRMWARE_UUID = UUID.fromString("5c3a659e-897e-45e1-b016-007107c96df8");
  private static final UUID DATA_TRANS_TX_UUID =
      UUID.fromString("5c3a659e-897e-45e1-b016-007107c96df9");
  private static final UUID DATA_TRANS_RX_UUID =
      UUID.fromString("5c3a659e-897e-45e1-b016-007107c96dfa");

  private BluetoothGattCharacteristic dataCharacteristic;
  private BluetoothGattCharacteristic voltageCharacteristic;
  private BluetoothGattCharacteristic writeDataCharacteristic;
  private BluetoothGattCharacteristic configCharacteristic;
  private BluetoothGattCharacteristic registersCharacteristic;
  private BluetoothGattCharacteristic firmwareCharacteristic;
  private BluetoothGattCharacteristic dataTransTxCharacteristic;
  private BluetoothGattCharacteristic dataTransRxCharacteristic;
  private SettableFuture<DeviceMode> deviceModeFuture;

  @Override
  public BluetoothPeripheralCallback getBluetoothPeripheralCallback() {
    return bluetoothPeripheralCallback;
  }

  @Override
  public boolean isDataCharacteristic(BluetoothGattCharacteristic characteristic) {
    return dataCharacteristic != null && characteristic.getUuid() == dataCharacteristic.getUuid();
  }

  @Override
  public int getTargetMTU() {
    return TARGET_MTU;
  }

  @Override
  public void connect(BluetoothPeripheral peripheral) {
    // H1 Device specific connection logic.
    this.peripheral = peripheral;
    initializeCharacteristics();
  }

  @Override
  public void disconnect(BluetoothPeripheral peripheral) {
    this.peripheral = null;
    clearCharacteristics();
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
        writeCharacteristic(writeDataCharacteristic, STOP_STREAMING);
        break;
      default:
        return Futures.immediateFailedFuture(new UnsupportedOperationException(
            "The " + deviceMode.toString() + " is not supported on this device."));
    }
    deviceModeFuture = SettableFuture.create();
    return deviceModeFuture;
  }

  private void writeCharacteristic(BluetoothGattCharacteristic characteristic, int[] value) {
    ByteBuffer byteBuffer = ByteBuffer.allocate(value.length * 4);
    IntBuffer intBuffer = byteBuffer.asIntBuffer();
    intBuffer.put(value);
    writeCharacteristic(characteristic, byteBuffer.array());
  }

  private void writeCharacteristic(BluetoothGattCharacteristic characteristic, byte[] value) {
    peripheral.writeCharacteristic(characteristic, value, WriteType.WITH_RESPONSE);
  }

  private void initializeCharacteristics() {
    dataCharacteristic = peripheral.getCharacteristic(SERVICE_UUID, DATA_UUID);
    checkCharacteristic(dataCharacteristic, SERVICE_UUID, DATA_UUID);
    voltageCharacteristic = peripheral.getCharacteristic(SERVICE_UUID, VOLTAGE_UUID);
    checkCharacteristic(voltageCharacteristic, SERVICE_UUID, VOLTAGE_UUID);
    writeDataCharacteristic = peripheral.getCharacteristic(SERVICE_UUID, WRITE_DATA_UUID);
    checkCharacteristic(writeDataCharacteristic, SERVICE_UUID, WRITE_DATA_UUID);
    configCharacteristic = peripheral.getCharacteristic(SERVICE_UUID, CONFIG_UUID);
    checkCharacteristic(configCharacteristic, SERVICE_UUID, CONFIG_UUID);
    registersCharacteristic = peripheral.getCharacteristic(SERVICE_UUID, REGISTERS_UUID);
    checkCharacteristic(registersCharacteristic, SERVICE_UUID, REGISTERS_UUID);
    firmwareCharacteristic = peripheral.getCharacteristic(SERVICE_UUID, FIRMWARE_UUID);
    checkCharacteristic(firmwareCharacteristic, SERVICE_UUID, FIRMWARE_UUID);
    dataTransTxCharacteristic = peripheral.getCharacteristic(SERVICE_UUID, DATA_TRANS_TX_UUID);
    checkCharacteristic(dataTransTxCharacteristic, SERVICE_UUID, DATA_TRANS_TX_UUID);
    dataTransRxCharacteristic = peripheral.getCharacteristic(SERVICE_UUID, DATA_TRANS_RX_UUID);
    checkCharacteristic(dataTransRxCharacteristic, SERVICE_UUID, DATA_TRANS_RX_UUID);
  }

  private void clearCharacteristics() {
    dataCharacteristic = null;
    voltageCharacteristic = null;
    writeDataCharacteristic = null;
    configCharacteristic = null;
    registersCharacteristic = null;
    firmwareCharacteristic = null;
    dataTransTxCharacteristic = null;
    dataTransRxCharacteristic = null;
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
            writeCharacteristic(writeDataCharacteristic, START_STREAMING);
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

    @Override
    public void onCharacteristicWrite(
        @NotNull BluetoothPeripheral peripheral, @NotNull byte[] value,
        @NotNull BluetoothGattCharacteristic characteristic, @NotNull GattStatus status) {
      int[] intValues = Util.getIntValues(value);
      Util.logv(TAG, "Characteristic write completed with status " + status.toString() +
          " with value: " + Arrays.toString(intValues));

      // Check mode change result.
      if (characteristic == writeDataCharacteristic && intValues.length == 1) {
        DeviceMode targetMode;
        if (intValues[0] == START_STREAMING[0]) {
          targetMode = DeviceMode.STREAMING;
        } else if (intValues[0] == STOP_STREAMING[0]) {
          targetMode = DeviceMode.IDLE;
        } else {
          // Not an expected value, return.
          return;
        }

        if (status == GattStatus.SUCCESS) {
          if (targetMode == DeviceMode.IDLE) {
            peripheral.setNotify(dataCharacteristic, /*enable=*/false);
          } else {
            deviceMode = targetMode;
            deviceModeFuture.set(targetMode);
          }
          Util.logd(TAG, "Wrote command to writeData characteristic with success.");
        } else {
          deviceModeFuture.setException(
              new BluetoothException("Failed to change the mode to " + targetMode.name() +
                  ", Bluetooth error code: " + status.name()));
        }
      }
    }
  };
}
