package io.nextsense.android.base.devices.kauai;

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

import org.greenrobot.eventbus.EventBus;
import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;

import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CancellationException;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

import io.nextsense.android.base.DeviceInfo;
import io.nextsense.android.base.DeviceMode;
import io.nextsense.android.base.DeviceSettings;
import io.nextsense.android.base.DeviceType;
import io.nextsense.android.base.KauaiFirmwareMessageProto;
import io.nextsense.android.base.communication.ble.BlePeripheralCallbackProxy;
import io.nextsense.android.base.communication.ble.BluetoothException;
import io.nextsense.android.base.data.LocalSessionManager;
import io.nextsense.android.base.devices.BaseNextSenseDevice;
import io.nextsense.android.base.devices.FirmwareMessageParsingException;
import io.nextsense.android.base.devices.NextSenseDevice;
import io.nextsense.android.base.devices.StreamingStartMode;
import io.nextsense.android.base.utils.RotatingFileLogger;

public class KauaiDevice extends BaseNextSenseDevice implements NextSenseDevice {
  public static final String BLUETOOTH_PREFIX = "NextSense EEG";

  public static final ByteOrder BYTE_ORDER = ByteOrder.BIG_ENDIAN;
  public static final String STREAM_START_MODE_KEY = "stream.start.mode";

  private static final String TAG = KauaiDevice.class.getSimpleName();
  private static final int TARGET_MTU = 256;
  private static final int CHANNELS_NUMBER = 6;

  private static final Duration COMMAND_TIMEOUT = Duration.ofSeconds(1);

  // TODO(eric): Set correct UUIDs.
  private static final UUID SERVICE_UUID = UUID.fromString("6e400001-b5a3-f393-e0a9-e50e24dcca9e");
  private static final UUID DATA_UUID = UUID.fromString("6e400003-b5a3-f393-e0a9-e50e24dcca9e");

  // TODO(eric): Set correct UUIDs.
  private static final UUID COMMANDS_UUID = UUID.fromString("6e400002-b5a3-f393-e0a9-e50e24dcca9e");
  private static final UUID NOTIFICATIONS_UUID = UUID.fromString("6e400004-b5a3-f393-e0a9-e50e24dcca9e");


  private final ListeningExecutorService executorService =
      MoreExecutors.listeningDecorator(Executors.newCachedThreadPool());
  // Names of channels, indexed starting with 1.
  private final List<Integer> enabledChannels = Arrays.asList(1, 2, 3, 4, 5, 6);

  private KauaiDataParser kauaiDataParser;
  private KauaiProtoDataParser kauaiProtoDataParser;
  private BlePeripheralCallbackProxy blePeripheralCallbackProxy;
  // Characteristic on which data streams are notified from the device.
  private BluetoothGattCharacteristic dataCharacteristic;
  // Read/Write characteristic where commands and info requests can be sent and the response read
  // back from.
  private BluetoothGattCharacteristic commandsCharacteristic;
  // Characteristic where the device can notify the host of state changes or events initiated on the
  // device.
  private BluetoothGattCharacteristic notificationsCharacteristic;
  private SettableFuture<Boolean> changeNotificationStateFuture;
  private SettableFuture<Boolean> changeStreamingStateFuture;
  private DeviceInfo deviceInfo = new DeviceInfo(DeviceType.KAUAI,
      DeviceInfo.UNKNOWN, DeviceInfo.UNKNOWN, DeviceInfo.UNKNOWN, DeviceInfo.UNKNOWN,
      DeviceInfo.UNKNOWN, DeviceInfo.UNKNOWN, DeviceInfo.UNKNOWN, DeviceInfo.UNKNOWN,
      DeviceInfo.UNKNOWN, DeviceInfo.UNKNOWN, DeviceInfo.UNKNOWN);
  private DeviceSettings deviceSettings;
  private StreamingStartMode targetStartStreamingMode;

  private SettableFuture<KauaiFirmwareMessageProto.HostMessage> commandResultFuture;
  // Id of the last message sent to the device. Used to verify the response message id.
  private int lastMessageId = -1;

  // Message type of the last message sent to the device. Used to verify the response message type.
  private KauaiFirmwareMessageProto.MessageType lastMessageType = null;

  // Needed for reflexion when created by Bluetooth device name.
  public KauaiDevice() {
    startListening();
  }

  public KauaiDevice(LocalSessionManager localSessionManager) {
    setLocalSessionManager(localSessionManager);
    startListening();
  }

  @Override
  public void setLocalSessionManager(LocalSessionManager localSessionManager) {
    super.localSessionManager = localSessionManager;
    kauaiDataParser = KauaiDataParser.create(getLocalSessionManager());
    kauaiProtoDataParser = KauaiProtoDataParser.create();
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

  public boolean isCommandsCharacteristic(BluetoothGattCharacteristic characteristic) {
    return commandsCharacteristic != null &&
        characteristic.getUuid() == commandsCharacteristic.getUuid();
  }

  public boolean isNotificationsCharacteristic(BluetoothGattCharacteristic characteristic) {
    return notificationsCharacteristic != null &&
        characteristic.getUuid() == notificationsCharacteristic.getUuid();
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
    return Arrays.asList("1", "2", "3", "4", "5", "6");
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
        // Set the time on the device.
        executeCommandNoResponse(new SetDateTimeCommand(
            lastMessageId++, String.valueOf(Instant.now().toEpochMilli())));
        // TODO(eric): Enable when the device sends a response to this command.
//        KauaiFirmwareMessageProto.HostMessage hostMessage = commandResultFuture.get(
//            COMMAND_TIMEOUT.toMillis(), TimeUnit.MILLISECONDS);
//        // Cannot read device settings, so load the default setting and apply them when connecting.
//        if (hostMessage.getResult().getErrorType() !=
//            KauaiFirmwareMessageProto.ErrorType.ERROR_NONE) {
//          RotatingFileLogger.get().loge(TAG, "Failed to set the time on the device: " +
//              hostMessage.getResult().getAdditionalInfo());
//          return false;
//        }
        loadDeviceInfo().get(COMMAND_TIMEOUT.toMillis(), TimeUnit.MILLISECONDS);
        // TODO(eric): call get_device_state here.
        loadDeviceSettings().get(
            COMMAND_TIMEOUT.toMillis(), TimeUnit.MILLISECONDS);
//        applyDeviceSettings(loadDeviceSettings().get(
//            COMMAND_TIMEOUT.toMillis(), TimeUnit.MILLISECONDS));
        RotatingFileLogger.get().logi(TAG, "Applied device settings.");
        // Enable notifications to get the device state change messages.
        if (!peripheral.isNotifying(notificationsCharacteristic)) {
          changeNotificationStateFuture = SettableFuture.create();
          peripheral.setNotify(notificationsCharacteristic, /*enable=*/true);
          return changeNotificationStateFuture.get();
        }
      } catch (ExecutionException e) {
        RotatingFileLogger.get().loge(TAG, "Failed to set the time on the device: " + e.getMessage());
        return false;
      } catch (InterruptedException e) {
        RotatingFileLogger.get().loge(TAG, "Interrupted when trying to set the time on the device: " + e.getMessage());
        Thread.currentThread().interrupt();
        return false;
      } catch (TimeoutException te) {
        RotatingFileLogger.get().loge(TAG, "Timeout getting the device ready: " +
            te.getMessage());
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
    if (dataCharacteristic == null || commandsCharacteristic == null) {
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
    return executorService.submit(() -> {
      // TODO(eric): enable when device supports this message.
//      executeCommandNoResponse(new SetRecordingOptionsCommand(lastMessageId++,
//          /*saveToFile=*/targetStartStreamingMode == StreamingStartMode.WITH_LOGGING,
//          /*continuousImpedance=*/false, (int)deviceSettings.getEegSamplingRate()));
//      KauaiFirmwareMessageProto.HostMessage hostMessage = commandResultFuture.get(
//          COMMAND_TIMEOUT.toMillis(), TimeUnit.MILLISECONDS);
//      if (hostMessage.getResult().getErrorType() !=
//          KauaiFirmwareMessageProto.ErrorType.ERROR_NONE) {
//        // TODO(eric): Pass error back to higher layer.
//        RotatingFileLogger.get().logw(TAG, "Failed to set recording options: " +
//            hostMessage.getResult().getErrorType() + ", " +
//            hostMessage.getResult().getAdditionalInfo());
//        return false;
//      }
      changeStreamingStateFuture = SettableFuture.create();
      if (!peripheral.isNotifying(dataCharacteristic)) {
        peripheral.setNotify(dataCharacteristic, /*enable=*/true);
      } else {
        runStartStreamingCommand();
      }
      return changeStreamingStateFuture.get(5000, TimeUnit.MILLISECONDS);
    });
  }

  @Override
  public ListenableFuture<Boolean> restartStreaming() {
    if (dataCharacteristic == null || commandsCharacteristic == null) {
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
      localSessionManager.stopLocalSession();
      return Futures.immediateFuture(true);
    }
    return executorService.submit(() -> {
      if (peripheral.getState() == ConnectionState.CONNECTED) {
        try {
          executeCommandNoResponse(new StopRecordingCommand(lastMessageId++));
          // TODO(eric): enable when device supports this message.
//          KauaiFirmwareMessageProto.HostMessage hostMessage = commandResultFuture.get(
//              COMMAND_TIMEOUT.toMillis(), TimeUnit.MILLISECONDS);
          // Cannot read device settings, so load the default setting and apply them when connecting.
//          if (hostMessage.getResult().getErrorType() !=
//              KauaiFirmwareMessageProto.ErrorType.ERROR_NONE) {
//            // TODO(eric): Pass error back to higher layer.
//            RotatingFileLogger.get().logw(TAG, "Failed to stop streaming: " +
//                hostMessage.getResult().getErrorType() + ", " +
//                hostMessage.getResult().getAdditionalInfo());
//            return false;
//          }
        } catch (CancellationException | ExecutionException e) {
          RotatingFileLogger.get().loge(TAG, "Failed to stop streaming: " + e.getMessage());
          localSessionManager.stopLocalSession();
          deviceMode = DeviceMode.IDLE;
          return false;
        } catch (InterruptedException e) {
          RotatingFileLogger.get().loge(TAG, "Interrupted when trying to stop streaming: " +
              e.getMessage());
          Thread.currentThread().interrupt();
          localSessionManager.stopLocalSession();
          deviceMode = DeviceMode.IDLE;
          return false;
        }
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
    return deviceInfo;
  }

  @Override
  public ListenableFuture<Boolean> applyDeviceSettings(DeviceSettings newDeviceSettings) {
    return executorService.submit(() -> {
      try {
        executeCommandNoResponse(new SetRecordingOptionsCommand(lastMessageId++,
            /*saveToFile=*/false, /*continuousImpedance=*/true,
            (int)newDeviceSettings.getEegSamplingRate()));
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
      // No command to load settings yet in Kauai, apply default values.
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

  public ListenableFuture<Boolean> loadDeviceInfo() {
    return executorService.submit(() -> {
      try {
        executeCommandNoResponse(new GetDeviceInfoCommand(lastMessageId++));
        readCommandResponse();
        KauaiFirmwareMessageProto.HostMessage hostMessage = commandResultFuture.get(
            COMMAND_TIMEOUT.toMillis(), TimeUnit.MILLISECONDS);
        if (hostMessage.getResult().getErrorType() !=
            KauaiFirmwareMessageProto.ErrorType.ERROR_NONE) {
          // TODO(eric): Pass error back to higher layer.
          RotatingFileLogger.get().logw(TAG, "Failed to get device info: " +
              hostMessage.getResult().getErrorType() + ", " +
              hostMessage.getResult().getAdditionalInfo());
          return true;
        }
        KauaiFirmwareMessageProto.DeviceInfo deviceInfoProto = hostMessage.getDeviceInfo();
        RotatingFileLogger.get().logi(TAG, "Device revision: " + deviceInfoProto.getDeviceRevision());
        RotatingFileLogger.get().logi(TAG, "Device type: " + deviceInfoProto.getDeviceType());
        RotatingFileLogger.get().logi(TAG, "Device serial: " + deviceInfoProto.getDeviceSerialNumber());
        RotatingFileLogger.get().logi(TAG, "Device time: " + Instant.ofEpochSecond(deviceInfoProto.getDeviceTimeEpochSeconds()).toString());
        RotatingFileLogger.get().logi(TAG, "FW major: " + deviceInfoProto.getFirmwareVersionMajor());
        RotatingFileLogger.get().logi(TAG, "FW minor: " + deviceInfoProto.getFirmwareVersionMinor());
        RotatingFileLogger.get().logi(TAG, "FW build number: " + deviceInfoProto.getFirmwareVersionBuildNumber());
        byte[] macAddressBytes = new byte[deviceInfoProto.getMacAddressList().size()];
        for (int i = 0; i < deviceInfoProto.getMacAddressList().size();++i) {
          macAddressBytes[i] = deviceInfoProto.getMacAddressList().get(i).byteValue();
        }
        String macAddress = new String(macAddressBytes, StandardCharsets.US_ASCII);
        RotatingFileLogger.get().logi(TAG, "Mac address: " + macAddress);
        this.deviceInfo = new DeviceInfo(
            DeviceType.KAUAI,
            String.valueOf(deviceInfoProto.getDeviceRevision()),
            String.valueOf(deviceInfoProto.getDeviceSerialNumber()),
            String.valueOf(deviceInfoProto.getFirmwareVersionMajor()),
            String.valueOf(deviceInfoProto.getFirmwareVersionMinor()),
            String.valueOf(deviceInfoProto.getFirmwareVersionBuildNumber()),
            String.valueOf(deviceInfoProto.getEarbudsType()),
            String.valueOf(deviceInfoProto.getEarbudsRevision()),
            String.valueOf(deviceInfoProto.getEarbudsSerialNumber()),
            DeviceInfo.UNKNOWN, DeviceInfo.UNKNOWN, DeviceInfo.UNKNOWN);
        return true;
      } catch (ExecutionException e) {
        RotatingFileLogger.get().loge(TAG, "Failed to get device settings: " + e.getMessage());
        return false;
      } catch (InterruptedException e) {
        RotatingFileLogger.get().loge(TAG, "Interrupted when trying to get device settings: " +
            e.getMessage());
        Thread.currentThread().interrupt();
        return false;
      }
    });
  }

  @Override
  public boolean requestDeviceInternalState() {
    try {
      executeCommandNoResponse(new GetDeviceStatusCommand(lastMessageId++));
      readCommandResponse();
      return true;
    } catch (CancellationException | ExecutionException | TimeoutException |
             FirmwareMessageParsingException e) {
      RotatingFileLogger.get().loge(TAG, "Failed to request the device state: " + e.getMessage());
      return false;
    } catch (InterruptedException e) {
      RotatingFileLogger.get().loge(TAG, "Interrupted when trying to request the device state: " + e.getMessage());
      Thread.currentThread().interrupt();
      return false;
    }
  }

  @Subscribe(threadMode = ThreadMode.BACKGROUND)
  public void onKauaiHostMessage(KauaiHostResponse hostResponse) {
    RotatingFileLogger.get().logv(TAG, "Received host message: " +
        hostResponse.getHostMessage().toString());
    if (commandResultFuture != null) {
      if (!verifyIsExpectedResponse(hostResponse)) {
        commandResultFuture.setException(new BluetoothException(
            "Received unexpected response: " + hostResponse.getHostMessage()));
      }
      commandResultFuture.set(hostResponse.getHostMessage());
    } else {
      RotatingFileLogger.get().logw(TAG, "No command was sent for this host message");
    }
  }

  @Subscribe(threadMode = ThreadMode.BACKGROUND)
  public void onKauaiHostEvent(KauaiHostEvent hostEvent) {
    // TODO(eric): Handle events. Should send them straight to Flutter layer as bytes for processing?
    RotatingFileLogger.get().logv(TAG, "Received host event: " +
        hostEvent.getHostMessage().toString());
    notifyDeviceInternalStateChangeListeners(hostEvent.getHostMessage().toByteArray());
  }

  public void startListening() {
    if (EventBus.getDefault().isRegistered(this)) {
      RotatingFileLogger.get().logw(TAG, "Already registered to EventBus!");
      return;
    }
    EventBus.getDefault().register(this);
    RotatingFileLogger.get().logi(TAG, "Started listening to EventBus.");
  }

  public void stopListening() {
    EventBus.getDefault().unregister(this);
    RotatingFileLogger.get().logi(TAG, "Stopped listening to EventBus.");
  }

  private boolean verifyIsExpectedResponse(KauaiHostResponse response) {
    if (lastMessageType == null || response == null || response.getHostMessage() == null) {
      RotatingFileLogger.get().logw(TAG, "Received null response or message type.");
      return false;
    }
    if (response.getHostMessage().getMessageType() != lastMessageType) {
      RotatingFileLogger.get().logw(TAG,
          "Received message type not matching the expected one. Expected: " +
          lastMessageType + ", received: " + response.getHostMessage().getMessageType());
      return false;
    }
    // TOD(eric): add back id verification when working correctly.
//    if (response.getHostMessage().getRespToMessageId() != lastMessageId) {
//      RotatingFileLogger.get().logw(TAG,
//          "Received message id not matching the expected one. Expected: " +
//          lastMessageId + ", received: " + response.getHostMessage().getRespToMessageId());
//      return false;
//    }
    return true;
  }

  private void writeCharacteristic(BluetoothGattCharacteristic characteristic, byte[] value) {
    peripheral.writeCharacteristic(characteristic, value, WriteType.WITHOUT_RESPONSE);
  }

  private void initializeCharacteristics() {
    dataCharacteristic = peripheral.getCharacteristic(SERVICE_UUID, DATA_UUID);
    checkCharacteristic(dataCharacteristic, SERVICE_UUID, DATA_UUID);
    commandsCharacteristic = peripheral.getCharacteristic(SERVICE_UUID, COMMANDS_UUID);
    checkCharacteristic(commandsCharacteristic, SERVICE_UUID, COMMANDS_UUID);
    notificationsCharacteristic = peripheral.getCharacteristic(SERVICE_UUID, NOTIFICATIONS_UUID);
    checkCharacteristic(notificationsCharacteristic, SERVICE_UUID, NOTIFICATIONS_UUID);
  }

  private void clearCharacteristics() {
    dataCharacteristic = null;
    commandsCharacteristic = null;
    notificationsCharacteristic = null;
  }

  private void executeCommandNoResponse(KauaiFirmwareMessage command) throws
      ExecutionException, InterruptedException, CancellationException {
    lastMessageType = command.getType();
    if (peripheral == null || commandsCharacteristic == null) {
      RotatingFileLogger.get().logw(TAG, "No peripheral to execute command on.");
      return;
    }
    RotatingFileLogger.get().logv(TAG, "Executing command: " + command.getType());
    blePeripheralCallbackProxy.writeCharacteristic(
        peripheral, commandsCharacteristic, command.getCommand(), WriteType.WITHOUT_RESPONSE).get();
  }

  private void readCommandResponse() throws
      ExecutionException, InterruptedException, CancellationException, TimeoutException,
      FirmwareMessageParsingException {
    if (peripheral == null || commandsCharacteristic == null) {
      RotatingFileLogger.get().logw(TAG, "No peripheral to read command response from.");
      return;
    }
    RotatingFileLogger.get().logv(TAG, "Reading command response.");
    commandResultFuture = SettableFuture.create();
    byte[] responseBytes = blePeripheralCallbackProxy.readCharacteristic(
        peripheral, commandsCharacteristic).get(
        COMMAND_TIMEOUT.toMillis(), TimeUnit.MILLISECONDS);
    RotatingFileLogger.get().logv(TAG, "Command bytes: " + Arrays.toString(responseBytes));
    kauaiProtoDataParser.parseProtoDataBytes(responseBytes);
  }

  private void runStartStreamingCommand() {
    try {
      executeCommandNoResponse(new StartRecordingCommand(lastMessageId++));
      // readCommandResponse();
      // TODO(eric): enable when device sends response to start recording command.
//      KauaiFirmwareMessageProto.HostMessage hostMessage = commandResultFuture.get(
//          COMMAND_TIMEOUT.toMillis(), TimeUnit.MILLISECONDS);
//      // Cannot read device settings, so load the default setting and apply them when connecting.
//      if (hostMessage.getResult().getErrorType() !=
//          KauaiFirmwareMessageProto.ErrorType.ERROR_NONE) {
//        // TODO(eric): Pass error back to higher layer.
//        RotatingFileLogger.get().logw(TAG, "Failed to start streaming: " +
//            hostMessage.getResult().getErrorType() + ", " +
//            hostMessage.getResult().getAdditionalInfo());
//      }
      RotatingFileLogger.get().logi(TAG, "Start recording command run successfully.");
      deviceMode = DeviceMode.STREAMING;
      changeStreamingStateFuture.set(true);
    } catch (CancellationException | ExecutionException e) {
      RotatingFileLogger.get().loge(TAG, "Failed to start streaming: " + e.getMessage());
      changeStreamingStateFuture.setException(e);
    } catch (InterruptedException e) {
      RotatingFileLogger.get().loge(TAG, "Interrupted when trying to start streaming: " +
          e.getMessage());
      changeStreamingStateFuture.setException(e);
      Thread.currentThread().interrupt();
    }
  }

  private final BluetoothPeripheralCallback bluetoothPeripheralCallback =
      new BluetoothPeripheralCallback() {
        @Override
        public void onNotificationStateUpdate(
            @NonNull BluetoothPeripheral peripheral,
            @NonNull BluetoothGattCharacteristic characteristic, @NonNull GattStatus status) {
          if (isDataCharacteristic(characteristic)) {
            if (changeStreamingStateFuture != null && !changeStreamingStateFuture.isDone()) {
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
          } else if (isNotificationsCharacteristic(characteristic) &&
              (changeNotificationStateFuture != null && !changeNotificationStateFuture.isDone())) {
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
          if (isDataCharacteristic(characteristic)) {
            try {
              kauaiDataParser.parseDataBytes(value, enabledChannels);
            } catch (FirmwareMessageParsingException e) {
              RotatingFileLogger.get().loge(TAG, "Failed to parse data bytes: " + e.getMessage());
            }
          } else if (isCommandsCharacteristic(characteristic) ||
              isNotificationsCharacteristic(characteristic)) {
            try {
              kauaiProtoDataParser.parseProtoDataBytes(value);
            } catch (FirmwareMessageParsingException e) {
              RotatingFileLogger.get().loge(TAG, "Failed to parse proto data bytes: " +
                  e.getMessage());
            }
          }
        }

        @Override
        public void onCharacteristicWrite(
            @NonNull BluetoothPeripheral peripheral, @NonNull byte[] value,
            @NonNull BluetoothGattCharacteristic characteristic, @NonNull GattStatus status) {
          RotatingFileLogger.get().logv(TAG, "Characteristic write completed with status " + status + " with value: " +
              Arrays.toString(value));
        }
      };
}
