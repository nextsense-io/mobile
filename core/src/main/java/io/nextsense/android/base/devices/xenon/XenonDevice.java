package io.nextsense.android.base.devices.xenon;

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
import com.welie.blessed.ConnectionState;
import com.welie.blessed.GattStatus;
import com.welie.blessed.WriteType;

import java.time.Instant;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CancellationException;
import java.util.concurrent.ExecutionException;
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
import io.nextsense.android.base.devices.StreamingStartMode;
import io.nextsense.android.base.utils.RotatingFileLogger;

/**
 * Second generation prototype device that was built internally at NextSense.
 * Dual-ear device with cross-ear channels.
 * Provides device information queries, configuration of a few parameters and data streaming.
 */
public class XenonDevice extends BaseNextSenseDevice implements NextSenseDevice {

  public static final String BLUETOOTH_PREFIX = "Xenon_P0.1";
  public static final String STREAM_START_MODE_KEY = "stream.start.mode";
  private static final String TAG = XenonDevice.class.getSimpleName();
  private static final int TARGET_MTU = 256;
  private static final int CHANNELS_NUMBER = 8;
  private static final UUID SERVICE_UUID = UUID.fromString("cb577fc4-7260-41f8-8216-3be734c7820a");
  private static final UUID DATA_UUID = UUID.fromString("59e33cfa-497d-4356-bb46-b87888419cb2");
  private static final DeviceInfo DEVICE_INFO = new DeviceInfo(
      DeviceType.XENON,
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
  private final List<Integer> enabledChannels = Arrays.asList(1, 3, 6, 7, 8);

  private XenonDataParser xenonDataParser;
  private BlePeripheralCallbackProxy blePeripheralCallbackProxy;
  private BluetoothGattCharacteristic dataCharacteristic;
  private SettableFuture<Boolean> changeNotificationStateFuture;
  private SettableFuture<Boolean> changeStreamingStateFuture;
  private DeviceSettings deviceSettings;
  private StreamingStartMode targetStartStreamingMode;

  // Needed for reflexion when created by Bluetooth device name.
  public XenonDevice() {}

  public XenonDevice(LocalSessionManager localSessionManager) {
    setLocalSessionManager(localSessionManager);
  }

  @Override
  public void setLocalSessionManager(LocalSessionManager localSessionManager) {
    super.localSessionManager = localSessionManager;
    xenonDataParser = XenonDataParser.create(getLocalSessionManager());
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
    if (reconnecting) {
      // If reconnecting, we do not want to reset the time and apply settings as there might be a
      // recording in progress and this is not supported.
      RotatingFileLogger.get().logi(TAG, "Reconnecting, no need to re-apply device settings.");
      return Futures.immediateFuture(true);
    }
    return executorService.submit(() -> {
      try {
        executeCommandNoResponse(new SetTimeCommand(Instant.now()));
        // Cannot read device settings, so load the default setting and apply them when connecting.
        applyDeviceSettings(loadDeviceSettings().get());
        RotatingFileLogger.get().logi(TAG, "Applied device settings.");
        // Enable notifications to get the device state change messages.
        if (!peripheral.isNotifying(dataCharacteristic)) {
          changeNotificationStateFuture = SettableFuture.create();
          peripheral.setNotify(dataCharacteristic, /*enable=*/true);
          return changeNotificationStateFuture.get();
        }
      } catch (ExecutionException e) {
        RotatingFileLogger.get().loge(TAG, "Failed to set the time on the device: " + e.getMessage());
        return false;
      } catch (InterruptedException e) {
        RotatingFileLogger.get().loge(TAG, "Interrupted when trying to set the time on the device: " + e.getMessage());
        Thread.currentThread().interrupt();
        return false;
      }
      return true;
    });
  }

  @Override
  public void disconnect(BluetoothPeripheral peripheral) {
    this.peripheral = null;
    clearCharacteristics();
  }

  @Override
  public ListenableFuture<Boolean> startStreaming(
      boolean uploadToCloud, @Nullable String userBigTableKey, @Nullable String dataSessionId,
      @Nullable String earbudsConfig, Bundle parameters) {
    if (parameters == null || parameters.getSerializable(STREAM_START_MODE_KEY) == null) {
      return Futures.immediateFailedFuture(
          new IllegalArgumentException("Need to provide the " + STREAM_START_MODE_KEY +
              " parameter."));
    }
    targetStartStreamingMode =
        (StreamingStartMode)parameters.getSerializable(STREAM_START_MODE_KEY);
    if (this.deviceMode == DeviceMode.STREAMING) {
      RotatingFileLogger.get().logw(TAG, "Device already streaming, nothing to do.");
      return Futures.immediateFuture(true);
    }
    if (dataCharacteristic == null) {
      return Futures.immediateFailedFuture(
          new IllegalStateException("No characteristic to stream on."));
    }
    long localSessionId = localSessionManager.startLocalSession(userBigTableKey, dataSessionId,
        earbudsConfig, uploadToCloud, deviceSettings.getEegStreamingRate(),
        deviceSettings.getImuStreamingRate());
    if (localSessionId == -1) {
      // Previous session not finished, cannot start streaming.
      RotatingFileLogger.get().logw(TAG, "Previous session not finished, cannot start streaming.");
      return Futures.immediateFuture(false);
    }
    changeStreamingStateFuture = SettableFuture.create();
    if (!peripheral.isNotifying(dataCharacteristic)) {
      peripheral.setNotify(dataCharacteristic, /*enable=*/true);
    } else {
      runStartStreamingCommand();
    }
    return changeStreamingStateFuture;
  }

  @Override
  public ListenableFuture<Boolean> restartStreaming() {
    if (dataCharacteristic == null) {
      return Futures.immediateFailedFuture(
          new IllegalStateException("No characteristic to stream on."));
    }
    changeStreamingStateFuture = SettableFuture.create();
    if (!peripheral.isNotifying(dataCharacteristic)) {
      peripheral.setNotify(dataCharacteristic, /*enable=*/true);
    } else {
      runStartStreamingCommand();
    }
    return changeStreamingStateFuture;
  }

  @Override
  public ListenableFuture<Boolean> stopStreaming() {
    if (this.deviceMode == DeviceMode.IDLE) {
      return Futures.immediateFuture(true);
    }
    return executorService.submit(() -> {
      if (peripheral.getState() == ConnectionState.CONNECTED) {
        writeCharacteristic(dataCharacteristic, new StopStreamingCommand().getCommand());
      }
      // TODO(eric): Wait until device ble buffer is empty before closing the session, or accept
      //             late packets as long as packets timestamps are valid?
      localSessionManager.stopLocalSession();
      deviceMode = DeviceMode.IDLE;
      return true;
    });
  }

  @Override
  public DeviceInfo getDeviceInfo() {
    return DEVICE_INFO;
  }

  @Override
  public ListenableFuture<Boolean> applyDeviceSettings(DeviceSettings newDeviceSettings) {
    return executorService.submit(() -> {
      try {
        executeCommandNoResponse(new SetConfigCommand(newDeviceSettings.getEnabledChannels(),
            newDeviceSettings.getImpedanceMode(), newDeviceSettings.getImpedanceDivider()));
        this.deviceSettings = newDeviceSettings;
        return true;
      } catch (ExecutionException e) {
        RotatingFileLogger.get().loge(TAG, "Failed to apply settings on the device: " + e.getMessage());
        return false;
      } catch (InterruptedException e) {
        RotatingFileLogger.get().loge(TAG, "Interrupted when trying to apply settings on the device: " +
            e.getMessage());
        Thread.currentThread().interrupt();
        return false;
      }
    });
  }

  @Override
  public ListenableFuture<DeviceSettings> loadDeviceSettings() {
    if (deviceSettings == null) {
      deviceSettings = new DeviceSettings();
      // No command to load settings yet in Xenon, apply default values.
      deviceSettings.setEnabledChannels(enabledChannels);
      deviceSettings.setEegSamplingRate(250);
      deviceSettings.setEegStreamingRate(250);
      deviceSettings.setImuSamplingRate(250);
      deviceSettings.setImuStreamingRate(250);
      deviceSettings.setImpedanceMode(DeviceSettings.ImpedanceMode.OFF);
      deviceSettings.setImpedanceDivider(25);
    }
    return Futures.immediateFuture(deviceSettings);
  }

  @Override
  public boolean requestDeviceInternalState() {
    try {
      executeCommandNoResponse(new RequestAuxPacketCommand());
      return true;
    } catch (CancellationException | ExecutionException e) {
      RotatingFileLogger.get().loge(TAG, "Failed to request the device state: " + e.getMessage());
      return false;
    } catch (InterruptedException e) {
      RotatingFileLogger.get().loge(TAG, "Interrupted when trying to request the device state: " + e.getMessage());
      Thread.currentThread().interrupt();
      return false;
    }
  }

  private void writeCharacteristic(BluetoothGattCharacteristic characteristic, byte[] value) {
    peripheral.writeCharacteristic(characteristic, value, WriteType.WITHOUT_RESPONSE);
  }

  private void initializeCharacteristics() {
    dataCharacteristic = peripheral.getCharacteristic(SERVICE_UUID, DATA_UUID);
    checkCharacteristic(dataCharacteristic, SERVICE_UUID, DATA_UUID);
  }

  private void clearCharacteristics() {
    dataCharacteristic = null;
  }

  private void executeCommandNoResponse(XenonFirmwareCommand command) throws
      ExecutionException, InterruptedException, CancellationException {
    if (peripheral == null || dataCharacteristic == null) {
      RotatingFileLogger.get().logw(TAG, "No peripheral to execute command on.");
      return;
    }
    blePeripheralCallbackProxy.writeCharacteristic(
        peripheral, dataCharacteristic, command.getCommand(), WriteType.WITHOUT_RESPONSE).get();
  }

  private void runStartStreamingCommand() {
    writeCharacteristic(
        dataCharacteristic, new StartStreamingCommand(targetStartStreamingMode).getCommand());
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
          if (peripheral.isNotifying(characteristic)) {
            runStartStreamingCommand();
          } else {
            localSessionManager.stopLocalSession();
            deviceMode = DeviceMode.IDLE;
            changeStreamingStateFuture.set(true);
          }
        } else {
          changeStreamingStateFuture.setException(new BluetoothException(
              "Notification state update failed with code " + status));
        }
      }
      if (changeNotificationStateFuture != null && !changeNotificationStateFuture.isDone() &&
          isDataCharacteristic(characteristic)) {
        if (status == GattStatus.SUCCESS) {
          RotatingFileLogger.get().logd(TAG, "Notification updated with success to " +
              peripheral.isNotifying(characteristic));
          changeNotificationStateFuture.set(true);
        } else {
          changeNotificationStateFuture.setException(new BluetoothException(
              "Notification state update failed with code " + status));
        }
      }
    }

    @Override
    public void onCharacteristicUpdate(
        @NonNull BluetoothPeripheral peripheral, @NonNull byte[] value,
        @NonNull BluetoothGattCharacteristic characteristic, @NonNull GattStatus status) {
      try {
        xenonDataParser.parseDataBytes(value, getChannelCount());
      } catch (FirmwareMessageParsingException e) {
        e.printStackTrace();
      }
    }

    @Override
    public void onCharacteristicWrite(
        @NonNull BluetoothPeripheral peripheral, @NonNull byte[] value,
        @NonNull BluetoothGattCharacteristic characteristic, @NonNull GattStatus status) {
      RotatingFileLogger.get().logv(TAG, "Characteristic write completed with status " + status + " with value: " +
          Arrays.toString(value));
      // Check mode change result.
      if (characteristic == dataCharacteristic &&
          value.length >= XenonFirmwareCommand.COMMAND_SIZE) {
        DeviceMode targetMode = DeviceMode.IDLE;
        byte[] command = Arrays.copyOfRange(value, 0, XenonFirmwareCommand.COMMAND_SIZE);
        if (Arrays.equals(command, XenonMessageType.START_STREAMING.getCode())) {
          targetMode = DeviceMode.STREAMING;
        } else if (Arrays.equals(command, XenonMessageType.STOP_STREAMING.getCode())) {
          targetMode = DeviceMode.IDLE;
        } else if (Arrays.equals(command, XenonMessageType.SET_CONFIG.getCode())) {
          // Not an expected value, return.
          return;
        }

        if (status == GattStatus.SUCCESS) {
          deviceMode = targetMode;
          if (changeStreamingStateFuture != null) {
            changeStreamingStateFuture.set(true);
          }
          RotatingFileLogger.get().logd(TAG, "Wrote command to writeData characteristic with success.");
        } else {
          if (changeStreamingStateFuture != null) {
            changeStreamingStateFuture.setException(
                new BluetoothException("Failed to change the mode to " + targetMode.name() +
                    ", Bluetooth error code: " + status.name()));
          }
        }
      }
    }
  };
}
