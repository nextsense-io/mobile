package io.nextsense.android.base.devices;

import android.bluetooth.BluetoothGattCharacteristic;
import android.util.Log;

import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;
import com.google.common.util.concurrent.SettableFuture;
import com.welie.blessed.BluetoothPeripheral;
import com.welie.blessed.BluetoothPeripheralCallback;
import com.welie.blessed.GattStatus;
import com.welie.blessed.WriteType;

import org.jetbrains.annotations.NotNull;

import java.nio.ByteBuffer;
import java.time.Instant;
import java.util.Arrays;
import java.util.UUID;
import java.util.concurrent.Future;

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
  private static final int MIN_BATTERY_VOLTAGE = 3600;
  private static final int MAX_BATTERY_VOLTAGE = 4194;
  private static final byte START_STREAMING = (byte)0x81;
  private static final byte STOP_STREAMING = (byte)0x80;
  private static final byte FIRMWARE_VERSION_CODE = (byte)0x01;
  private static final byte BATTERY_INFO_CODE = (byte)0x02;
  private static final byte BATTERY_STATUS_CODE = (byte)0x03;
  private static final byte TIME_SYNC_FLAG_CODE = (byte)0x04;
  private static final byte TIME_SET_ID_CODE = (byte)0x05;
  private static final byte GET_TIME_CODE = (byte)0x06;


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
  public Future<?> connect(BluetoothPeripheral peripheral) {
    // H1 Device specific connection logic.
    this.peripheral = peripheral;
    initializeCharacteristics();
    setTime();
    // TODO(eric): Use a future when setting the time.
    return Futures.immediateFuture(null);
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
        writeCharacteristic(writeDataCharacteristic, new byte[]{STOP_STREAMING});
        break;
      default:
        return Futures.immediateFailedFuture(new UnsupportedOperationException(
            "The " + deviceMode.toString() + " is not supported on this device."));
    }
    deviceModeFuture = SettableFuture.create();
    return deviceModeFuture;
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

  private String padString(String string, int length) {
    return String.format("%1$" + length + "s", string).replace(' ', '0');
  }

  private byte[] getSetTimeCommand(Instant time) {
    long seconds = time.getEpochSecond();
    ByteBuffer buf = ByteBuffer.allocate(13);
    buf.put(TIME_SET_ID_CODE);
    String secondsHex = padString(Long.toHexString(seconds), /*length=*/8);
    for (char character : secondsHex.toCharArray()) {
      buf.put((byte)character);
    }
    String timeZone = "0000";
    for (char character : timeZone.toCharArray()) {
      buf.put((byte)character);
    }
    buf.rewind();
    byte[] message = buf.array();
    Log.i(TAG, "Setting the device time to " + Arrays.toString(message));
    return message;
  }

  private void setTime() {
    byte[] command = getSetTimeCommand(Instant.now());
    writeCharacteristic(dataTransRxCharacteristic, command);
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
            writeCharacteristic(writeDataCharacteristic, new byte[]{START_STREAMING});
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
      Util.logv(TAG, "Characteristic write completed with status " + status.toString() +
          " with value: " + Arrays.toString(value));
      // Check mode change result.
      if (characteristic == writeDataCharacteristic && value.length == 1) {
        DeviceMode targetMode;
        if (value[0] == START_STREAMING) {
          targetMode = DeviceMode.STREAMING;
        } else if (value[0] == STOP_STREAMING) {
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
