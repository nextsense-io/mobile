package io.nextsense.android.base.devices.maui;

import android.bluetooth.BluetoothGattCharacteristic;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;
import com.google.common.util.concurrent.ListeningExecutorService;
import com.google.common.util.concurrent.MoreExecutors;
import com.google.common.util.concurrent.SettableFuture;
import com.welie.blessed.BluetoothPeripheral;
import com.welie.blessed.BluetoothPeripheralCallback;
import com.welie.blessed.GattStatus;

import java.util.List;
import java.util.UUID;
import java.util.concurrent.Executors;
import java.util.stream.Collectors;

import io.nextsense.android.base.DeviceInfo;
import io.nextsense.android.base.DeviceMode;
import io.nextsense.android.base.DeviceSettings;
import io.nextsense.android.base.DeviceType;
import io.nextsense.android.base.communication.ble.BlePeripheralCallbackProxy;
import io.nextsense.android.base.communication.ble.BluetoothException;
import io.nextsense.android.base.data.LocalSessionManager;
import io.nextsense.android.base.devices.BaseNextSenseDevice;
import io.nextsense.android.base.devices.FirmwareMessageParsingException;
import io.nextsense.android.base.devices.NextSenseDevice;
import io.nextsense.android.base.utils.RotatingFileLogger;

// Maui is a Bluetooth Classic first device. This class represents a BLE data stream from one ear
// only.
public class MauiDevice extends BaseNextSenseDevice implements NextSenseDevice {

  public static final String BLUETOOTH_PREFIX = "AH203_BLE";
  private static final String TAG = MauiDevice.class.getSimpleName();
  private static final int TARGET_MTU = 512;
  private static final int CHANNELS_NUMBER = 1;
  private static final UUID SERVICE_UUID = UUID.fromString("7319494d-2dab-0341-6972-6f6861424c45");
  private static final UUID DATA_UUID = UUID.fromString("73194152-2dab-3141-6972-6f6861424c45");
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

  private final ListeningExecutorService executorService =
      MoreExecutors.listeningDecorator(Executors.newCachedThreadPool());
  // Names of channels, indexed starting with 1.
  private final List<Integer> enabledChannels = List.of(1);
  private MauiDataParser mauiDataParser;
  private BlePeripheralCallbackProxy blePeripheralCallbackProxy;
  private BluetoothGattCharacteristic dataCharacteristic;
  private SettableFuture<Boolean> changeNotificationStateFuture;
  private SettableFuture<Boolean> changeStreamingStateFuture;
  private DeviceSettings deviceSettings;

  // Needed for reflexion when created by Bluetooth device name.
  public MauiDevice() {}

  public MauiDevice(LocalSessionManager localSessionManager) {
    setLocalSessionManager(localSessionManager);
  }

  @Override
  public void setLocalSessionManager(LocalSessionManager localSessionManager) {
    super.localSessionManager = localSessionManager;
    mauiDataParser = MauiDataParser.create(getLocalSessionManager());
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
  public List<String> getEegChannelNames() {
    return enabledChannels.stream().map(String::valueOf).collect(Collectors.toList());
  }

  @Override
  public ListenableFuture<Boolean> connect(BluetoothPeripheral peripheral, boolean reconnecting) {
    this.peripheral = peripheral;
    initializeCharacteristics();
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
    boolean saveToCsv = false;
    if (parameters != null && parameters.containsKey(LocalSessionManager.SAVE_TO_CSV_KEY)) {
      saveToCsv = parameters.getBoolean(LocalSessionManager.SAVE_TO_CSV_KEY, false);
    }
    long localSessionId = localSessionManager.startLocalSession(userBigTableKey, dataSessionId,
        earbudsConfig, uploadToCloud, deviceSettings.getEegStreamingRate(),
        deviceSettings.getImuStreamingRate(), saveToCsv);
    if (localSessionId == -1) {
      // Previous session not finished, cannot start streaming.
      RotatingFileLogger.get().logw(TAG, "Previous session not finished, cannot start streaming.");
      return Futures.immediateFuture(false);
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
    localSessionManager.stopActiveLocalSession();
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
      // No command to load settings yet in Nitro, apply default values.
      deviceSettings.setEnabledChannels(List.of(1));
      deviceSettings.setEegSamplingRate(1000f);
      deviceSettings.setEegStreamingRate(1000f);
      deviceSettings.setImuSamplingRate(1f);
      deviceSettings.setImuStreamingRate(1f);
      deviceSettings.setImpedanceMode(DeviceSettings.ImpedanceMode.OFF);
      deviceSettings.setImpedanceDivider(25);
    }
    return Futures.immediateFuture(deviceSettings);
  }

  @Override
  public ListenableFuture<Boolean> restartStreaming() {
    return Futures.immediateFuture(true);
  }

  private void initializeCharacteristics() {
    dataCharacteristic = peripheral.getCharacteristic(SERVICE_UUID, DATA_UUID);
    checkCharacteristic(dataCharacteristic, SERVICE_UUID, DATA_UUID);
  }

  private void clearCharacteristics() {
    dataCharacteristic = null;
  }

  private final BluetoothPeripheralCallback bluetoothPeripheralCallback =
      new BluetoothPeripheralCallback() {
        @Override
        public void onNotificationStateUpdate(
            @NonNull BluetoothPeripheral peripheral,
            @NonNull BluetoothGattCharacteristic characteristic, @NonNull GattStatus status) {
          if (changeStreamingStateFuture != null && !changeStreamingStateFuture.isDone() &&
              isDataCharacteristic(characteristic)) {
            if (status == GattStatus.SUCCESS) {
              RotatingFileLogger.get().logd(TAG, "Notification updated with success to " +
                  peripheral.isNotifying(characteristic));
              deviceMode = peripheral.isNotifying(characteristic) ? DeviceMode.STREAMING :
                  DeviceMode.IDLE;
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
          try {
            mauiDataParser.parseDataBytes(value);
          } catch (FirmwareMessageParsingException e) {
            RotatingFileLogger.get().loge(TAG, "Failed to parse data bytes: " + e.getMessage());
          }
        }
      };
}