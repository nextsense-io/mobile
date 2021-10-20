package io.nextsense.android.base.devices.h1;

import android.bluetooth.BluetoothGattCharacteristic;
import android.os.Bundle;

import androidx.annotation.NonNull;

import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;
import com.google.common.util.concurrent.ListeningExecutorService;
import com.google.common.util.concurrent.MoreExecutors;
import com.google.common.util.concurrent.SettableFuture;
import com.welie.blessed.BluetoothPeripheral;
import com.welie.blessed.BluetoothPeripheralCallback;
import com.welie.blessed.GattStatus;
import com.welie.blessed.WriteType;

import java.time.Instant;
import java.util.Arrays;
import java.util.UUID;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Executors;

import io.nextsense.android.base.DeviceMode;
import io.nextsense.android.base.data.LocalSessionManager;
import io.nextsense.android.base.utils.Util;
import io.nextsense.android.base.communication.ble.BlePeripheralCallbackProxy;
import io.nextsense.android.base.communication.ble.BluetoothException;
import io.nextsense.android.base.devices.BaseNextSenseDevice;
import io.nextsense.android.base.devices.FirmwareMessageParsingException;
import io.nextsense.android.base.devices.NextSenseDevice;

/**
 * First Generation device that was built at Google X with Culvert Engineering.
 * Dual-ear device with cross-ear channels. Channels 1, 2 and 5 plus the optosync on channel 7 are
 * typically enabled.
 * Provides device information queries, configuration of a few parameters and data streaming.
 */
public class H1Device extends BaseNextSenseDevice implements NextSenseDevice {

  public static final String BLUETOOTH_PREFIX = "Heimdallr";
  public static final int MIN_BATTERY_VOLTAGE = 3600;
  public static final int MAX_BATTERY_VOLTAGE = 4194;

  private static final String TAG = H1Device.class.getSimpleName();
  private static final int TARGET_MTU = 256;
  private static final int CHANNELS_NUMBER = 8;

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

  private final ListeningExecutorService executorService =
      MoreExecutors.listeningDecorator(Executors.newCachedThreadPool());

  private H1DataParser h1DataParser;
  private BlePeripheralCallbackProxy blePeripheralCallbackProxy;
  private BluetoothGattCharacteristic dataCharacteristic;
  private BluetoothGattCharacteristic voltageCharacteristic;
  private BluetoothGattCharacteristic writeDataCharacteristic;
  private BluetoothGattCharacteristic configCharacteristic;
  private BluetoothGattCharacteristic registersCharacteristic;
  private BluetoothGattCharacteristic firmwareCharacteristic;
  private BluetoothGattCharacteristic dataTransTxCharacteristic;
  private BluetoothGattCharacteristic dataTransRxCharacteristic;
  private SettableFuture<Boolean> deviceModeFuture;

  // Needed for reflexion when created by Bluetooth device name.
  public H1Device() {}

  public H1Device(LocalSessionManager localSessionManager) {
    setLocalSessionManager(localSessionManager);
  }

  @Override
  public void setLocalSessionManager(LocalSessionManager localSessionManager) {
    super.localSessionManager = localSessionManager;
    h1DataParser = H1DataParser.create(getLocalSessionManager());
  }

  @Override
  public void setBluetoothPeripheralProxy(BlePeripheralCallbackProxy proxy) {
    blePeripheralCallbackProxy = proxy;
    blePeripheralCallbackProxy.addPeripheralCallbackListener(bluetoothPeripheralCallback);
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
  public int getChannelCount() {
    return CHANNELS_NUMBER;
  }

  @Override
  public ListenableFuture<Boolean> connect(BluetoothPeripheral peripheral) {
    this.peripheral = peripheral;
    initializeCharacteristics();
    return executorService.submit(() -> {
      SetTimeResponse setTimeResponse = setTime().get();
      if (setTimeResponse == null) {
        throw new FirmwareMessageParsingException(
            "Could not parse the setTime response");
      }
      return setTimeResponse.getTimeSet();
    });
  }

  @Override
  public void disconnect(BluetoothPeripheral peripheral) {
    this.peripheral = null;
    clearCharacteristics();
  }

  @Override
  public ListenableFuture<Boolean> startStreaming(boolean uploadToCloud, Bundle parameters) {
    if (this.deviceMode == DeviceMode.STREAMING) {
      return Futures.immediateFuture(true);
    }
    if (dataCharacteristic == null) {
      return Futures.immediateFailedFuture(
          new IllegalStateException("No characteristic to stream on."));
    }
    deviceModeFuture = SettableFuture.create();
    localSessionManager.startLocalSession(/*cloudSessionId=*/null, uploadToCloud);
    peripheral.setNotify(dataCharacteristic, /*enable=*/true);
    return deviceModeFuture;
  }

  @Override
  public ListenableFuture<Boolean> stopStreaming() {
    deviceModeFuture = SettableFuture.create();
    writeCharacteristic(writeDataCharacteristic, new StopStreamingCommand().getCommand());
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

  // TODO(eric): Could encapsulate this in the SetTimeCommand with a "Communication" interface
  //     implemented by Bluetooth.
  private ListenableFuture<SetTimeResponse> setTime() {
    return executorService.submit(() -> {
        SetTimeResponse setTimeResponse =
            (SetTimeResponse) executeCommand(new SetTimeCommand(Instant.now()));
        if (setTimeResponse.getTimeSet()) {
          Util.logd(TAG, "Time set with success");
        }
        return setTimeResponse;
      }
    );
  }

  private H1FirmwareResponse executeCommand(H1FirmwareCommand command) throws
      ExecutionException, InterruptedException, FirmwareMessageParsingException {
    blePeripheralCallbackProxy.writeCharacteristic(
        peripheral, dataTransRxCharacteristic, command.getCommand(), WriteType.WITH_RESPONSE).get();
    byte[] readValue = blePeripheralCallbackProxy.readCharacteristic(
        peripheral, dataTransTxCharacteristic).get();
    H1FirmwareResponse response = H1DataParser.parseDataTransRxBytes(readValue);
    if (response.getType() == command.getType()) {
      return response;
    } else {
      throw new FirmwareMessageParsingException("Expected response type of " +
          command.getType().name() + " but got " + response.getType().name());
    }
  }

  private final BluetoothPeripheralCallback bluetoothPeripheralCallback =
      new BluetoothPeripheralCallback() {
    @Override
    public void onNotificationStateUpdate(
        @NonNull BluetoothPeripheral peripheral,
        @NonNull BluetoothGattCharacteristic characteristic, @NonNull GattStatus status) {
      if (!deviceModeFuture.isDone() && isDataCharacteristic(characteristic)) {
        if (status == GattStatus.SUCCESS) {
          Util.logd(TAG, "Notification updated with success to " +
              peripheral.isNotifying(characteristic));
          if (peripheral.isNotifying(characteristic)) {
            writeCharacteristic(writeDataCharacteristic,
                new StartStreamingCommand(/*writeToSdcard=*/true).getCommand());
          } else {
            localSessionManager.stopLocalSession();
            deviceMode = DeviceMode.IDLE;
            deviceModeFuture.set(true);
          }
        } else {
          deviceModeFuture.setException(new BluetoothException(
              "Notification state update failed with code " + status));
        }
      }
    }

    @Override
    public void onCharacteristicUpdate(
        @NonNull BluetoothPeripheral peripheral, @NonNull byte[] value,
        @NonNull BluetoothGattCharacteristic characteristic, @NonNull GattStatus status) {
      try {
        h1DataParser.parseDataBytes(value, getChannelCount());
      } catch (FirmwareMessageParsingException e) {
        e.printStackTrace();
      }
    }

    @Override
    public void onCharacteristicWrite(
        @NonNull BluetoothPeripheral peripheral, @NonNull byte[] value,
        @NonNull BluetoothGattCharacteristic characteristic, @NonNull GattStatus status) {
      Util.logv(TAG, "Characteristic write completed with status " + status.toString() +
          " with value: " + Arrays.toString(value));
      // Check mode change result.
      if (characteristic == writeDataCharacteristic &&
          value.length >= H1FirmwareCommand.COMMAND_SIZE) {
        DeviceMode targetMode;
        if (value[0] == H1MessageType.START_STREAMING.getCode()) {
          targetMode = DeviceMode.STREAMING;
        } else if (value[0] == H1MessageType.STOP_STREAMING.getCode()) {
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
            deviceModeFuture.set(true);
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
