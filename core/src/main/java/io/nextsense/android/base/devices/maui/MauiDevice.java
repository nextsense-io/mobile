package io.nextsense.android.base.devices.maui;

import android.bluetooth.BluetoothGattCharacteristic;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;
import com.google.common.util.concurrent.SettableFuture;
import com.welie.blessed.BluetoothPeripheral;
import com.welie.blessed.BluetoothPeripheralCallback;
import com.welie.blessed.GattStatus;
import com.welie.blessed.WriteType;

import java.nio.ByteOrder;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CancellationException;
import java.util.concurrent.ExecutionException;
import java.util.stream.Collectors;

import io.nextsense.android.base.DeviceInfo;
import io.nextsense.android.base.DeviceMode;
import io.nextsense.android.base.DeviceSettings;
import io.nextsense.android.base.DeviceType;
import io.nextsense.android.base.communication.ble.BlePeripheralCallbackProxy;
import io.nextsense.android.base.communication.ble.BluetoothException;
import io.nextsense.android.base.data.Acceleration;
import io.nextsense.android.base.data.AngularSpeed;
import io.nextsense.android.base.data.LocalSessionManager;
import io.nextsense.android.base.devices.BaseNextSenseDevice;
import io.nextsense.android.base.devices.FirmwareMessageParsingException;
import io.nextsense.android.base.devices.NextSenseDevice;
import io.nextsense.android.base.utils.RotatingFileLogger;

// Maui is a Bluetooth Classic first device. This class represents a BLE data stream from one ear
// only.
public class MauiDevice extends BaseNextSenseDevice implements NextSenseDevice {

  public static final String BLUETOOTH_PREFIX_LEFT = "AH203_L";
  public static final String BLUETOOTH_PREFIX_RIGHT = "AH203_R";
  public static final ByteOrder BYTE_ORDER = ByteOrder.LITTLE_ENDIAN;
  public static final String EARBUD_CONFIG = "maui_config";
  private static final String TAG = MauiDevice.class.getSimpleName();
  private static final int TARGET_MTU = 512;
  private static final int CHANNELS_NUMBER = 2;
  private static final UUID SERVICE_UUID = UUID.fromString("7319494d-2dab-0341-6972-6f6861424c45");
  private static final UUID DATA_UUID = UUID.fromString("73194152-2dab-3141-6972-6f6861424c45");
  private static final UUID CONTROL_UUID = UUID.fromString("73194152-2dab-3241-6972-6f6861424c45");
  private static final DeviceInfo DEVICE_INFO = new DeviceInfo(
      DeviceType.MAUI,
      DeviceInfo.UNKNOWN,
      DeviceInfo.UNKNOWN,
      DeviceInfo.UNKNOWN,
      DeviceInfo.UNKNOWN,
      DeviceInfo.UNKNOWN,
      DeviceInfo.UNKNOWN,
      DeviceInfo.UNKNOWN,
      DeviceInfo.UNKNOWN,
      DeviceInfo.UNKNOWN,
      DeviceInfo.UNKNOWN,
      DeviceInfo.UNKNOWN);

  // Names of channels, indexed starting with 1.
  private final List<Integer> enabledChannels = List.of(1, 2);
  private MauiDataParser mauiDataParser;
  private BlePeripheralCallbackProxy blePeripheralCallbackProxy;
  private BluetoothGattCharacteristic dataCharacteristic;
  private BluetoothGattCharacteristic controlCharacteristic;
  private SettableFuture<Boolean> changeStreamingStateFuture;
  private DeviceSettings deviceSettings;

  // Needed for reflexion when created by Bluetooth device name.
  @SuppressWarnings("unused")
  public MauiDevice() {}

  public MauiDevice(LocalSessionManager localSessionManager) {
    setLocalSessionManager(localSessionManager);
  }

  @Override
  public void setLocalSessionManager(LocalSessionManager localSessionManager) {
    super.localSessionManager = localSessionManager;
    mauiDataParser = MauiDataParser.create(getLocalSessionManager());
  }

  public void setDataSynchronizers(DataSynchronizer eegDataSynchronizer,
                                   DataSynchronizer imuDataSynchronizer) {
    mauiDataParser.setDataSynchronizers(eegDataSynchronizer, imuDataSynchronizer);
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

  private boolean isControlCharacteristic(BluetoothGattCharacteristic characteristic) {
    return controlCharacteristic != null && characteristic.getUuid() == controlCharacteristic.getUuid();
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
  public List<String> getEegChannelNames() {
    return enabledChannels.stream().map(String::valueOf).collect(Collectors.toList());
  }

  @Override
  public List<String> getAccChannelNames() {
    return Arrays.asList(Acceleration.Channels.ACC_R_X.getName(),
        Acceleration.Channels.ACC_R_Y.getName(), Acceleration.Channels.ACC_R_Z.getName(),
        Acceleration.Channels.ACC_L_X.getName(), Acceleration.Channels.ACC_L_Y.getName(),
        Acceleration.Channels.ACC_L_Z.getName(), AngularSpeed.Channels.GYRO_R_X.getName(),
        AngularSpeed.Channels.GYRO_R_Y.getName(), AngularSpeed.Channels.GYRO_R_Z.getName(),
        AngularSpeed.Channels.GYRO_L_X.getName(), AngularSpeed.Channels.GYRO_L_Y.getName(),
        AngularSpeed.Channels.GYRO_L_Z.getName());
  }

  @Override
  public ListenableFuture<Boolean> connect(BluetoothPeripheral peripheral, boolean reconnecting) {
    this.peripheral = peripheral;
    mauiDataParser.setDeviceName(peripheral.getName());
    initializeCharacteristics();
    // TODO: Implement once firmware supports.
//    if (!peripheral.isNotifying(controlCharacteristic)) {
//      changeStreamingStateFuture = SettableFuture.create();
//      peripheral.setNotify(controlCharacteristic, /*enable=*/true);
//      return changeStreamingStateFuture;
//    }
    return Futures.immediateFuture(true);
  }

  @Override
  public void disconnect(BluetoothPeripheral peripheral) {
    this.peripheral = null;
    clearCharacteristics();
  }

  @Override
  public boolean requestDeviceInternalState() {
    // Not implemented.
    return false;
  }

  @Override
  public ListenableFuture<Boolean> startStreaming(
      boolean uploadToCloud, @Nullable String userBigTableKey, @Nullable String dataSessionId,
      @Nullable String earbudsConfig, Bundle parameters) {
    if (this.deviceMode == DeviceMode.STREAMING) {
      RotatingFileLogger.get().logw(TAG, "Device already streaming, nothing to do.");
      return Futures.immediateFuture(true);
    }
    if (dataCharacteristic == null) {
      return Futures.immediateFailedFuture(
          new IllegalStateException("No characteristic to stream on."));
    }
    mauiDataParser.startNewSession();
    if (!peripheral.isNotifying(dataCharacteristic)) {
      changeStreamingStateFuture = SettableFuture.create();
      peripheral.setNotify(dataCharacteristic, /*enable=*/true);
      return changeStreamingStateFuture;
    }
    return Futures.immediateFuture(true);
  }

  @Override
  public ListenableFuture<Boolean> stopStreaming() {
    if (this.deviceMode == DeviceMode.IDLE) {
      return Futures.immediateFuture(true);
    }
    deviceMode = DeviceMode.IDLE;
    if (peripheral.isNotifying(dataCharacteristic)) {
      changeStreamingStateFuture = SettableFuture.create();
      peripheral.setNotify(dataCharacteristic, /*enable=*/false);
      return changeStreamingStateFuture;
    }
    return Futures.immediateFuture(true);
  }

  @Override
  public DeviceInfo getDeviceInfo() {
    return DEVICE_INFO;
  }

  @Override
  public ListenableFuture<DeviceSettings> loadDeviceSettings() {
    if (deviceSettings == null) {
      deviceSettings = new DeviceSettings();
      // No command to load settings yet in Maui, apply default values.
      deviceSettings.setEnabledChannels(List.of(1, 2));
      deviceSettings.setEegSamplingRate(1000f);
      deviceSettings.setEegStreamingRate(1000f);
      deviceSettings.setImuSamplingRate(100f);
      deviceSettings.setImuStreamingRate(100f);
      deviceSettings.setImpedanceMode(DeviceSettings.ImpedanceMode.OFF);
      deviceSettings.setImpedanceDivider(25);
    }
    return Futures.immediateFuture(deviceSettings);
  }

  @Override
  public ListenableFuture<Boolean> restartStreaming() {
    return Futures.immediateFuture(true);
  }

  public byte[] writeWithResponse(byte[] data) throws
      ExecutionException, InterruptedException, CancellationException {
    if (peripheral == null || controlCharacteristic == null) {
      RotatingFileLogger.get().logw(TAG, "No peripheral to write with response.");
      return new byte[0];
    }
    RotatingFileLogger.get().logi(TAG, "Writing with response: " + Arrays.toString(data) + " on " +
        peripheral.getName());
    blePeripheralCallbackProxy.writeCharacteristic(
        peripheral, controlCharacteristic, data, WriteType.WITH_RESPONSE).get();
    return blePeripheralCallbackProxy.readCharacteristic(peripheral, controlCharacteristic).get();
  }

  private void initializeCharacteristics() {
    dataCharacteristic = peripheral.getCharacteristic(SERVICE_UUID, DATA_UUID);
    checkCharacteristic(dataCharacteristic, SERVICE_UUID, DATA_UUID);
    controlCharacteristic = peripheral.getCharacteristic(SERVICE_UUID, CONTROL_UUID);
    checkCharacteristic(controlCharacteristic, SERVICE_UUID, CONTROL_UUID);
  }

  private void clearCharacteristics() {
    dataCharacteristic = null;
    controlCharacteristic = null;
  }

  private void executeCommandNoResponse(byte[] bytes) throws
      ExecutionException, InterruptedException, CancellationException {
    if (peripheral == null || controlCharacteristic == null) {
      RotatingFileLogger.get().logw(TAG, "No peripheral to execute command on.");
      return;
    }
    RotatingFileLogger.get().logi(TAG, "Executing command: " + Arrays.toString(bytes) + " on " +
        peripheral.getName());
    blePeripheralCallbackProxy.writeCharacteristic(
        peripheral, controlCharacteristic, bytes, WriteType.WITHOUT_RESPONSE).get();
  }

  @Override
  public void writeControlCharacteristic(byte[] bytes) throws
      ExecutionException, InterruptedException, CancellationException {
    if (peripheral == null || controlCharacteristic == null) {
      RotatingFileLogger.get().logw(TAG, "No peripheral to write control characteristic.");
      return;
    }
    RotatingFileLogger.get().logi(TAG, "Writing control characteristic: " + Arrays.toString(bytes) +
        " on " + peripheral.getName());
    blePeripheralCallbackProxy.writeCharacteristic(
        peripheral, controlCharacteristic, bytes, WriteType.WITH_RESPONSE).get();
  }

  private final BluetoothPeripheralCallback bluetoothPeripheralCallback =
      new BluetoothPeripheralCallback() {
        @Override
        public void onNotificationStateUpdate(
            @NonNull BluetoothPeripheral peripheral,
            @NonNull BluetoothGattCharacteristic characteristic, @NonNull GattStatus status) {
          if (changeStreamingStateFuture != null && !changeStreamingStateFuture.isDone()) {
            if (status == GattStatus.SUCCESS) {
              RotatingFileLogger.get().logd(TAG, "Notification updated with success to " +
                  peripheral.isNotifying(characteristic));
              if (isDataCharacteristic(characteristic)) {
                if (peripheral.isNotifying(characteristic)) {
                  deviceMode = DeviceMode.STREAMING;
                } else {
                  deviceMode = DeviceMode.IDLE;
                }
              }
              changeStreamingStateFuture.set(true);
            } else {
              changeStreamingStateFuture.setException(new BluetoothException(
                  "Notification state update failed with code " + status));
            }
          }
        }

        @Override
        public void onCharacteristicUpdate(
            @NonNull BluetoothPeripheral peripheral, @NonNull byte[] value,
            @NonNull BluetoothGattCharacteristic characteristic, @NonNull GattStatus status) {
          if (isDataCharacteristic(characteristic)) {
            try {
              mauiDataParser.parseDataBytes(value);
            } catch (FirmwareMessageParsingException e) {
              RotatingFileLogger.get().loge(TAG, "Failed to parse data bytes: " + e.getMessage());
            }
          } else if (isControlCharacteristic(characteristic)) {
            RotatingFileLogger.get().logd(TAG, "Control characteristic update: " +
                Arrays.toString(value));
            for (ControlCharacteristicListener listener : controlCharacteristicListeners) {
              listener.onControlCharacteristicUpdate(value);
            }
          }
        }
      };
}
