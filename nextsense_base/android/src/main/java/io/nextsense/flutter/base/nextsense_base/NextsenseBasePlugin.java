package io.nextsense.flutter.base.nextsense_base;

import android.bluetooth.BluetoothAdapter;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Environment;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.os.StatFs;

import androidx.annotation.NonNull;

import com.google.common.collect.Maps;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.TimeZone;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

import javax.annotation.Nullable;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.StandardMethodCodec;
import io.nextsense.android.Config;
import io.nextsense.android.base.Device;
import io.nextsense.android.base.DeviceInfo;
import io.nextsense.android.base.DeviceManager;
import io.nextsense.android.base.DeviceMode;
import io.nextsense.android.base.DeviceScanner;
import io.nextsense.android.base.DeviceSettings.ImpedanceMode;
import io.nextsense.android.base.DeviceState;
import io.nextsense.android.base.communication.internet.Connectivity;
import io.nextsense.android.base.data.DeviceInternalState;
import io.nextsense.android.base.data.LocalSession;
import io.nextsense.android.base.data.LocalSessionManager;
import io.nextsense.android.base.devices.NextSenseDevice;
import io.nextsense.android.base.emulated.EmulatedDeviceManager;
import io.nextsense.android.base.utils.RotatingFileLogger;
import io.nextsense.android.service.ForegroundService;
import io.objectbox.android.AndroidScheduler;
import io.objectbox.reactive.DataSubscription;

/** NextSenseBasePlugin */
public class NextsenseBasePlugin implements FlutterPlugin, MethodCallHandler {
  public static final String CONNECT_TO_SERVICE_COMMAND = "connect_to_service";
  public static final String STOP_SERVICE_COMMAND = "stop_service";
  public static final String CHANGE_NOTIFICATION_CONTENT = "change_notification_content";
  public static final String SET_FLUTTER_ACTIVITY_ACTIVE_COMMAND = "set_flutter_activity_active";
  public static final String IS_FLUTTER_ACTIVITY_ACTIVE_COMMAND = "is_flutter_activity_active";
  public static final String CONNECT_DEVICE_COMMAND = "connect_device";
  public static final String DISCONNECT_DEVICE_COMMAND = "disconnect_device";
  public static final String CAN_START_NEW_SESSION_COMMAND = "can_start_new_session";
  public static final String START_STREAMING_COMMAND = "start_streaming";
  public static final String STOP_STREAMING_COMMAND = "stop_streaming";
  public static final String IS_DEVICE_STREAMING_COMMAND = "is_device_streaming";
  public static final String START_IMPEDANCE_COMMAND = "start_impedance";
  public static final String STOP_IMPEDANCE_COMMAND = "stop_impedance";
  public static final String SET_IMPEDANCE_CONFIG_COMMAND = "set_impedance_config";
  public static final String GET_CONNECTED_DEVICES_COMMAND = "get_connected_devices";
  public static final String GET_DEVICE_INFO_COMMAND = "get_device_info";
  public static final String GET_DEVICE_STATE_COMMAND = "get_device_state";
  public static final String GET_DEVICE_SETTINGS_COMMAND = "get_device_settings";
  public static final String GET_CHANNEL_DATA_COMMAND = "get_channel_data";
  public static final String GET_ACC_CHANNEL_DATA_COMMAND = "get_acc_channel_data";
  public static final String GET_TIMESTAMPS_DATA_COMMAND = "get_timestamps_data";
  public static final String DELETE_LOCAL_SESSION_COMMAND = "delete_local_session";
  public static final String REQUEST_DEVICE_INTERNAL_STATE_COMMAND =
      "request_device_internal_state";
  public static final String GET_DEVICE_INTERNAL_STATE_DATA_COMMAND =
      "get_device_internal_state_data";
  public static final String SET_UPLOADER_MINIMUM_CONNECTIVITY_COMMAND =
      "set_uploader_minimum_connectivity";
  public static final String GET_FREE_DISK_SPACE_COMMAND = "get_free_disk_space";
  public static final String GET_TIMEZONE_ID_COMMAND = "get_timezone_id";

  public static final String GET_NATIVE_LOGS_COMMAND = "get_native_logs";
  public static final String RUN_SLEEP_STAGING_COMMAND = "run_sleep_staging";
  public static final String EMULATOR_COMMAND = "emulator_command";
  public static final String IS_BLUETOOTH_ENABLED_ARGUMENT = "is_bluetooth_enabled";
  public static final String MAC_ADDRESS_ARGUMENT = "mac_address";
  public static final String FROM_DATABASE_ARGUMENT = "from_database";
  public static final String UPLOAD_TO_CLOUD_ARGUMENT = "upload_to_cloud";
  public static final String CONTINUOUS_IMPEDANCE_ARGUMENT = "continuous_impedance";
  public static final String USER_BT_KEY_ARGUMENT = "user_bigtable_key";
  public static final String DATA_SESSION_ID_ARGUMENT = "data_session_id";
  public static final String EARBUDS_CONFIG_ARGUMENT = "earbuds_config";
  public static final String LOCAL_SESSION_ID_ARGUMENT = "local_session_id";
  public static final String CHANNEL_NUMBER_ARGUMENT = "channel_number";
  public static final String DURATION_MILLIS_ARGUMENT = "duration_millis";
  public static final String IMPEDANCE_MODE_ARGUMENT = "impedance_mode";
  public static final String FREQUENCY_DIVIDER_ARGUMENT = "frequency_divider";
  public static final String MIN_CONNECTION_TYPE_ARGUMENT = "min_connection_type";
  public static final String NOTIFICATION_TITLE_ARGUMENT = "notification_title";
  public static final String START_DATE_TIME_EPOCH_MS_ARGUMENT = "start_date_time_epoch_ms";
  public static final String NOTIFICATION_TEXT_ARGUMENT = "notification_text";
  public static final String ERROR_SERVICE_NOT_AVAILABLE = "service_not_available";
  public static final String ERROR_DEVICE_NOT_FOUND = "not_found";
  public static final String ERROR_SESSION_NOT_STARTED = "session_not_started";
  public static final String ERROR_STREAMING_START_FAILED = "streaming_start_failed";
  public static final String ERROR_STREAMING_STOP_FAILED = "streaming_stop_failed";
  public static final String ERROR_COMMAND_FAILED = "command_failed";
  public static final String CONNECT_TO_DEVICE_ERROR_CONNECTION = "connection_error";
  public static final String CONNECT_TO_DEVICE_ERROR_INTERRUPTED = "connection_interrupted";

  private static final String TAG = NextsenseBasePlugin.class.getSimpleName();
  private static final String METHOD_CHANNEL_NAME = "nextsense_base";
  private static final String DEVICE_SCAN_CHANNEL_NAME =
      "io.nextsense.flutter.base.nextsense_base/device_scan_channel";
  private static final String DEVICE_STATE_CHANNEL_NAME =
      "io.nextsense.flutter.base.nextsense_base/device_state_channel";
  private static final String DEVICE_INTERNAL_STATE_CHANNEL_NAME =
      "io.nextsense.flutter.base.nextsense_base/device_internal_state_channel";

  private static final String DEVICE_EVENT_CHANNEL_NAME =
      "io.nextsense.flutter.base.nextsense_base/device_events_channel";

  private static final String CURRENT_SESSION_DATA_RECEIVED_CHANNEL_NAME =
      "io.nextsense.flutter.base.nextsense_base/current_session_data_received_channel";

  // Handler for the UI thread which is needed for running flutter JNI methods.
  private final Handler uiThreadHandler = new Handler(Looper.getMainLooper());
  private final Gson gson;
  private final Map<String, Device.DeviceStateChangeListener> deviceStateListeners =
      Maps.newConcurrentMap();

  private final Map<String, NextSenseDevice.DeviceInternalStateChangeListener>
      deviceInternalStateListeners = Maps.newConcurrentMap();
  private LocalSessionManager.OnFirstDataReceivedListener onCurrentSessionDataReceivedListener;
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel methodChannel;
  private EventChannel deviceScanChannel;
  private EventChannel deviceStateChannel;
  private EventChannel deviceEventChannel;
  private EventChannel deviceInternalStateChannel;
  private EventChannel currentSessionDataReceivedChannel;
  private Context applicationContext;
  private Intent foregroundServiceIntent;
  private ForegroundService nextSenseService;
  private boolean nextSenseServiceBound = false;
  private DeviceManager.DeviceScanListener deviceScanListener;
  private AndroidScheduler deviceEventChannelSubscriptionScheduler;
  private AndroidScheduler deviceInternalStateSubscriptionScheduler;
  private DataSubscription deviceInternalStateSubscription;

  public NextsenseBasePlugin() {
    GsonBuilder gsonBuilder = new GsonBuilder();
    gsonBuilder.excludeFieldsWithoutExposeAnnotation();
    gson = gsonBuilder.create();
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    RotatingFileLogger.get().logi(TAG, "Attaching to engine.");
    BinaryMessenger messenger = flutterPluginBinding.getBinaryMessenger();
    BinaryMessenger.TaskQueue taskQueue = messenger.makeBackgroundTaskQueue();
    methodChannel =
        new MethodChannel(messenger, METHOD_CHANNEL_NAME, StandardMethodCodec.INSTANCE, taskQueue);
    methodChannel.setMethodCallHandler(this);
    RotatingFileLogger.get().logi(TAG, "Getting context.");
    applicationContext = flutterPluginBinding.getApplicationContext();

    deviceScanChannel =
        new EventChannel(flutterPluginBinding.getBinaryMessenger(), DEVICE_SCAN_CHANNEL_NAME);
    deviceScanChannel.setStreamHandler(new EventChannel.StreamHandler() {
      @Override
      public void onListen(Object listener, EventChannel.EventSink eventSink) {
        RotatingFileLogger.get().logi(TAG, "Starting Android Bluetooth scan...");
        startScanning(eventSink);
      }
      @Override
      public void onCancel(Object listener) {
        stopScanning();
      }
    });

    deviceStateChannel =
        new EventChannel(flutterPluginBinding.getBinaryMessenger(), DEVICE_STATE_CHANNEL_NAME);
    deviceStateChannel.setStreamHandler(new EventChannel.StreamHandler() {
      @Override
      @SuppressWarnings("unchecked")
      public void onListen(Object arguments, EventChannel.EventSink eventSink) {
        RotatingFileLogger.get().logi(TAG, "Starting to listen to Android device state...");
        List<Object> argumentList = (ArrayList<Object>) arguments;
        startListeningToDeviceState(eventSink, (String) argumentList.get(1));
      }
      @Override
      @SuppressWarnings("unchecked")
      public void onCancel(Object arguments) {
        if (arguments == null) {
          return;
        }
        List<Object> argumentList = (ArrayList<Object>) arguments;
        stopListeningToDeviceState((String) argumentList.get(1));
      }
    });

    deviceEventChannelSubscriptionScheduler =
        new AndroidScheduler(applicationContext.getMainLooper());
    deviceEventChannel =
        new EventChannel(flutterPluginBinding.getBinaryMessenger(), DEVICE_EVENT_CHANNEL_NAME);
    deviceEventChannel.setStreamHandler(new EventChannel.StreamHandler() {
      @Override
      @SuppressWarnings("unchecked")
      public void onListen(Object arguments, EventChannel.EventSink eventSink) {
        RotatingFileLogger.get().logi(TAG, "Starting to listen to device events...");
        List<Object> argumentList = (ArrayList<Object>) arguments;
        startListeningToDeviceEvents(eventSink, (String) argumentList.get(1));
      }
      @Override
      @SuppressWarnings("unchecked")
      public void onCancel(Object arguments) {
        List<Object> argumentList = (ArrayList<Object>) arguments;
        stopListeningToDeviceEvents((String) argumentList.get(1));
      }
    });

    deviceInternalStateSubscriptionScheduler =
        new AndroidScheduler(applicationContext.getMainLooper());
    deviceInternalStateChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(),
        DEVICE_INTERNAL_STATE_CHANNEL_NAME);
    deviceInternalStateChannel.setStreamHandler(new EventChannel.StreamHandler() {
      @Override
      public void onListen(Object arguments, EventChannel.EventSink eventSink) {
        RotatingFileLogger.get().logi(TAG, "Starting to listen to internal device state...");
        startListeningToInternalDeviceState(eventSink);
      }
      @Override
      public void onCancel(Object arguments) {
        stopListeningToInternalDeviceState();
      }
    });
    currentSessionDataReceivedChannel =
        new EventChannel(flutterPluginBinding.getBinaryMessenger(),
            CURRENT_SESSION_DATA_RECEIVED_CHANNEL_NAME);
    currentSessionDataReceivedChannel.setStreamHandler(new EventChannel.StreamHandler() {
      @Override
      @SuppressWarnings("unchecked")
      public void onListen(Object arguments, EventChannel.EventSink eventSink) {
        RotatingFileLogger.get().logi(TAG, "Starting to listen to current session data received state...");
        starListeningToCurrentSessionDataReceived(eventSink);
      }
      @Override
      @SuppressWarnings("unchecked")
      public void onCancel(Object arguments) {
        stopListeningToCurrentSessionDataReceived();
      }
    });
    RotatingFileLogger.get().logi(TAG, "Attached to engine.");
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    RotatingFileLogger.get().logi(TAG, "Detaching from engine.");
    if (deviceInternalStateSubscription != null) {
      deviceInternalStateSubscription.cancel();
      deviceInternalStateSubscription = null;
    }
    methodChannel.setMethodCallHandler(null);
    deviceScanChannel.setStreamHandler(null);
    deviceStateChannel.setStreamHandler(null);
    deviceInternalStateChannel.setStreamHandler(null);
    currentSessionDataReceivedChannel.setStreamHandler(null);
    applicationContext = null;
    RotatingFileLogger.get().logi(TAG, "Detached from engine.");
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method) {
      case "getPlatformVersion":
        result.success("Android " + android.os.Build.VERSION.RELEASE);
        break;
      case CONNECT_TO_SERVICE_COMMAND:
        connectToService();
        result.success(null);
        break;
      case STOP_SERVICE_COMMAND:
        stopService();
        result.success(null);
        break;
      case CHANGE_NOTIFICATION_CONTENT:
        String title = call.argument(NOTIFICATION_TITLE_ARGUMENT);
        String text = call.argument(NOTIFICATION_TEXT_ARGUMENT);
        changeServiceNotificationContent(title, text);
        result.success(null);
        break;
      case CONNECT_DEVICE_COMMAND:
        String macAddress = call.argument(MAC_ADDRESS_ARGUMENT);
        RotatingFileLogger.get().logd(TAG, "connecting to device: " + macAddress);
        connectDevice(result, macAddress);
        RotatingFileLogger.get().logd(TAG, "connected to device: " + macAddress + " with result " + result);
        break;
      case DISCONNECT_DEVICE_COMMAND:
        macAddress = call.argument(MAC_ADDRESS_ARGUMENT);
        RotatingFileLogger.get().logd(TAG, "disconnecting from device: " + macAddress);
        disconnectDevice(result, macAddress);
        RotatingFileLogger.get().logd(TAG, "disconnected from device: " + macAddress + " with result " +
            result);
        break;
      case IS_BLUETOOTH_ENABLED_ARGUMENT:
        if (!Config.USE_EMULATED_BLE)
          result.success(BluetoothAdapter.getDefaultAdapter().isEnabled());
        else
          result.success(true);
        break;
      case CAN_START_NEW_SESSION_COMMAND:
        canStartNewSession(result);
        break;
      case START_STREAMING_COMMAND:
        macAddress = call.argument(MAC_ADDRESS_ARGUMENT);
        Boolean uploadToCloud = call.argument(UPLOAD_TO_CLOUD_ARGUMENT);
        String userBtKey = call.argument(USER_BT_KEY_ARGUMENT);
        String dataSessionId = call.argument(DATA_SESSION_ID_ARGUMENT);
        String earbudsConfig = call.argument(EARBUDS_CONFIG_ARGUMENT);
        startStreaming(result, macAddress, uploadToCloud, userBtKey, dataSessionId, earbudsConfig);
        break;
      case STOP_STREAMING_COMMAND:
        macAddress = call.argument(MAC_ADDRESS_ARGUMENT);
        stopStreaming(result, macAddress);
        break;
      case START_IMPEDANCE_COMMAND:
        macAddress = call.argument(MAC_ADDRESS_ARGUMENT);
        String impedanceModeName = call.argument(IMPEDANCE_MODE_ARGUMENT);
        Integer channelNumber = call.argument(CHANNEL_NUMBER_ARGUMENT);
        Integer frequencyDivider = call.argument(FREQUENCY_DIVIDER_ARGUMENT);
        startImpedance(result, macAddress, impedanceModeName, channelNumber, frequencyDivider);
        break;
      case IS_DEVICE_STREAMING_COMMAND:
        macAddress = call.argument(MAC_ADDRESS_ARGUMENT);
        isDeviceStreaming(result, macAddress);
        break;
      case STOP_IMPEDANCE_COMMAND:
        macAddress = call.argument(MAC_ADDRESS_ARGUMENT);
        stopImpedance(result, macAddress);
        break;
      case SET_IMPEDANCE_CONFIG_COMMAND:
        macAddress = call.argument(MAC_ADDRESS_ARGUMENT);
        impedanceModeName = call.argument(IMPEDANCE_MODE_ARGUMENT);
        channelNumber = call.argument(CHANNEL_NUMBER_ARGUMENT);
        frequencyDivider = call.argument(FREQUENCY_DIVIDER_ARGUMENT);
        setImpedanceConfig(result, macAddress, impedanceModeName, channelNumber, frequencyDivider);
        break;
      case GET_CONNECTED_DEVICES_COMMAND:
        getConnectedDevices(result);
        break;
      case GET_DEVICE_INFO_COMMAND:
        macAddress = call.argument(MAC_ADDRESS_ARGUMENT);
        getDeviceInfo(result, macAddress);
        break;
      case GET_DEVICE_STATE_COMMAND:
        macAddress = call.argument(MAC_ADDRESS_ARGUMENT);
        getDeviceState(result, macAddress);
        break;
      case GET_DEVICE_SETTINGS_COMMAND:
        macAddress = call.argument(MAC_ADDRESS_ARGUMENT);
        getDeviceSettings(result, macAddress);
        break;
      case GET_CHANNEL_DATA_COMMAND:
        macAddress = call.argument(MAC_ADDRESS_ARGUMENT);
        Integer localSessionId = call.argument(LOCAL_SESSION_ID_ARGUMENT);
        String channelName = call.argument(CHANNEL_NUMBER_ARGUMENT);
        Integer durationMillis = call.argument(DURATION_MILLIS_ARGUMENT);
        Boolean fromDatabase= call.argument(FROM_DATABASE_ARGUMENT);
        getChannelData(result, macAddress, localSessionId, channelName, durationMillis,
            fromDatabase);
        break;
      case GET_ACC_CHANNEL_DATA_COMMAND:
        macAddress = call.argument(MAC_ADDRESS_ARGUMENT);
        localSessionId = call.argument(LOCAL_SESSION_ID_ARGUMENT);
        channelName = call.argument(CHANNEL_NUMBER_ARGUMENT);
        durationMillis = call.argument(DURATION_MILLIS_ARGUMENT);
        fromDatabase= call.argument(FROM_DATABASE_ARGUMENT);
        getAccChannelData(result, macAddress, localSessionId, channelName, durationMillis,
            fromDatabase);
        break;
      case GET_TIMESTAMPS_DATA_COMMAND:
        macAddress = call.argument(MAC_ADDRESS_ARGUMENT);
        durationMillis = call.argument(DURATION_MILLIS_ARGUMENT);
        getTimestampsData(result, macAddress, durationMillis);
        break;
      case DELETE_LOCAL_SESSION_COMMAND:
        localSessionId = call.argument(LOCAL_SESSION_ID_ARGUMENT);
        deleteLocalSession(result, localSessionId);
        break;
      case REQUEST_DEVICE_INTERNAL_STATE_COMMAND:
        macAddress = call.argument(MAC_ADDRESS_ARGUMENT);
        requestDeviceInternalStateUpdate(result, macAddress);
        break;
      case GET_DEVICE_INTERNAL_STATE_DATA_COMMAND:
        macAddress = call.argument(MAC_ADDRESS_ARGUMENT);
        localSessionId = call.argument(LOCAL_SESSION_ID_ARGUMENT);
        durationMillis = call.argument(DURATION_MILLIS_ARGUMENT);
        getDeviceInternalStateData(result, macAddress, localSessionId, durationMillis);
        break;
      case SET_UPLOADER_MINIMUM_CONNECTIVITY_COMMAND:
        String minConnectionType = call.argument(MIN_CONNECTION_TYPE_ARGUMENT);
        setUploaderMinimumConnectivity(result, minConnectionType);
        break;
      case GET_FREE_DISK_SPACE_COMMAND:
        getFreeDiskSpace(result);
        break;
      case GET_TIMEZONE_ID_COMMAND:
        getTimezoneId(result);
        break;
      case GET_NATIVE_LOGS_COMMAND:
        getNativeLogs(result);
        break;
      case RUN_SLEEP_STAGING_COMMAND:
        macAddress = call.argument(MAC_ADDRESS_ARGUMENT);
        localSessionId = call.argument(LOCAL_SESSION_ID_ARGUMENT);
        channelName = call.argument(CHANNEL_NUMBER_ARGUMENT);
        Instant startDateTime =
            Instant.ofEpochMilli(call.argument(START_DATE_TIME_EPOCH_MS_ARGUMENT));
        durationMillis = call.argument(DURATION_MILLIS_ARGUMENT);
        fromDatabase= call.argument(FROM_DATABASE_ARGUMENT);
        runSleepStaging(result, macAddress, localSessionId, channelName, startDateTime,
            durationMillis, fromDatabase);
        break;
      case EMULATOR_COMMAND:
        String command = call.argument("command");
        Map<String, Object> params = call.argument("params");
        DeviceManager deviceManager = nextSenseService.getDeviceManager();
        if (deviceManager instanceof EmulatedDeviceManager) {
          ((EmulatedDeviceManager)deviceManager).sendEmulatorCommand(command, params);
        }
        break;
      case SET_FLUTTER_ACTIVITY_ACTIVE_COMMAND:
        if (nextSenseServiceBound) {
          nextSenseService.setFlutterActivityActive((boolean)call.arguments);
        } else {
          RotatingFileLogger.get().logd(TAG, "flutter_start: service not connected.");
        }
        break;
      case IS_FLUTTER_ACTIVITY_ACTIVE_COMMAND:
        if (nextSenseServiceBound) {
          result.success(nextSenseService.isFlutterActivityActive());
        }
        result.success(false);
        break;
      default:
        result.notImplemented();
    }
  }

  private void requestDeviceInternalStateUpdate(Result result, String macAddress) {
    Optional<Device> device = nextSenseService.getDeviceManager().getDevice(macAddress);
    if (!device.isPresent()) {
      returnError(result, REQUEST_DEVICE_INTERNAL_STATE_COMMAND, ERROR_DEVICE_NOT_FOUND,
          /*errorMessage=*/null, /*errorDetails=*/null);
      return;
    }
    boolean requested = device.get().requestDeviceState();
    if (!requested) {
      returnError(result, REQUEST_DEVICE_INTERNAL_STATE_COMMAND, ERROR_COMMAND_FAILED,
          /*errorMessage=*/null, /*errorDetails=*/null);
      return;
    }
    result.success(null);
  }

  private void connectToService() {
    if (nextSenseServiceBound) {
      return;
    }
    if (applicationContext != null) {
      try {
        Class<?> uiClass = Class.forName(
            "io.flutter.embedding.android.FlutterActivity");
        RotatingFileLogger.get().logi(TAG, "Creating intent.");
        foregroundServiceIntent = new Intent(applicationContext, ForegroundService.class);
        foregroundServiceIntent.putExtra("ui_class", uiClass);
        applicationContext.startService(foregroundServiceIntent);
        applicationContext.bindService(foregroundServiceIntent, nextSenseConnection,
            Context.BIND_IMPORTANT);
      } catch (ClassNotFoundException e) {
        RotatingFileLogger.get().loge(TAG, "Could not find class: " +
            "io.flutter.embedding.android.FlutterActivity");
      }
    } else {
      RotatingFileLogger.get().logd(TAG, "context still null");
    }
  }

  private void stopService() {
    if (applicationContext != null) {
      applicationContext.stopService(foregroundServiceIntent);
    } else {
      RotatingFileLogger.get().logd(TAG, "context still null");
    }
  }

  private void changeServiceNotificationContent(String title, String text) {
    if (nextSenseServiceBound) {
      nextSenseService.changeNotificationContent(title, text);
    }
  }

  private DeviceAttributes getDeviceAttributesFromDevice(Device device) {
    return new DeviceAttributes(device.getAddress(), device.getName(),
        device.getInfo().getType().name(), device.getInfo().getRevision(),
        device.getInfo().getSerialNumber(), device.getInfo().getFirmwareVersionMajor(),
        device.getInfo().getFirmwareVersionMinor(),
        device.getInfo().getFirmwareVersionBuildNumber(),
        device.getInfo().getEarbudsType(), device.getInfo().getEarbudsRevision(),
        device.getInfo().getEarbudsSerialNumber(), device.getInfo().getEarbudsVersionMajor(),
        device.getInfo().getEarbudsVersionMinor(), device.getInfo().getEarbudsVersionBuildNumber());
  }

  private void getConnectedDevices(Result result) {
    List<String> connectedDevicesJson = new ArrayList<>();
    if (nextSenseServiceBound) {
      List<Device> connectedDevices = nextSenseService.getDeviceManager().getConnectedDevices();
      for (Device device : connectedDevices) {
        connectedDevicesJson.add(
            gson.toJson(getDeviceAttributesFromDevice(device)));
      }
    }
    result.success(connectedDevicesJson);
  }

  private void getDeviceState(Result result, String macAddress) {
    Optional<Device> device = nextSenseService.getDeviceManager().getDevice(macAddress);
    if (!device.isPresent()) {
      returnError(result, GET_DEVICE_STATE_COMMAND, ERROR_DEVICE_NOT_FOUND,
          /*errorMessage=*/null, /*errorDetails=*/null);
      return;
    }
    result.success(device.get().getState().name());
  }

  private void startScanning(EventChannel.EventSink eventSink) {
    if (nextSenseServiceBound) {
      deviceScanListener = new DeviceManager.DeviceScanListener() {
        @Override
        public void onNewDevice(Device device) {
          RotatingFileLogger.get().logi(TAG, "Found a device in Android scan: " + device.getName());
          DeviceAttributes deviceAttributes = getDeviceAttributesFromDevice(device);
          uiThreadHandler.post(() -> eventSink.success(gson.toJson(deviceAttributes)));
        }

        @Override
        public void onScanError(DeviceScanner.ScanError scanError) {
          RotatingFileLogger.get().loge(TAG, "Error while scanning in Android: " + scanError.name());
          uiThreadHandler.post(() ->
              eventSink.error(scanError.name(), scanError.name(), scanError.name()));
        }
      };
      nextSenseService.getDeviceManager().findDevices(deviceScanListener);
    } else {
      RotatingFileLogger.get().logw(TAG, "Service not connected, cannot start Bluetooth scan.");
    }
  }

  private void stopScanning() {
    if (nextSenseServiceBound && deviceScanListener != null) {
      nextSenseService.getDeviceManager().stopFindingDevices(deviceScanListener);
      deviceScanListener = null;
    } else {
      RotatingFileLogger.get().logd(TAG, "Service not connected.");
    }
  }

  private void startListeningToDeviceState(EventChannel.EventSink eventSink, String macAddress) {
    if (nextSenseServiceBound) {
      Optional<Device> device = nextSenseService.getDeviceManager().getDevice(macAddress);
      if (!device.isPresent()) {
        uiThreadHandler.post(() ->
            eventSink.error(ERROR_DEVICE_NOT_FOUND, /*errorMessage=*/null,
                /*errorDetails=*/null));
        return;
      }
      deviceStateListeners.put(macAddress, newDeviceState ->
          uiThreadHandler.post(() -> eventSink.success(newDeviceState.name())));
      device.get().addOnDeviceStateChangeListener(deviceStateListeners.get(macAddress));
    } else {
      RotatingFileLogger.get().logw(TAG, "Service not connected, cannot start monitoring device state.");
    }
  }

  public void stopListeningToDeviceState(String macAddress) {
    if (nextSenseServiceBound) {
      Optional<Device> device = nextSenseService.getDeviceManager().getDevice(macAddress);
      if (!device.isPresent()) {
        RotatingFileLogger.get().logw(TAG, "Cannot find the device " + macAddress +
            " when trying to stop listening to its state.");
        return;
      }
      Device.DeviceStateChangeListener deviceStateListener = deviceStateListeners.get(macAddress);
      if (deviceStateListener != null) {
        device.get().removeOnDeviceStateChangeListener(deviceStateListener);
        RotatingFileLogger.get().logi(TAG, "Stopped listening to Android device state for " + macAddress);
      }
    } else {
      RotatingFileLogger.get().logw(TAG, "Service not connected, cannot start monitoring device state.");
    }
  }

  // TODO(eric): fill out device events methods.
  private void startListeningToDeviceEvents(EventChannel.EventSink eventSink, String macAddress) {
    if (nextSenseServiceBound) {
      Optional<Device> device = nextSenseService.getDeviceManager().getDevice(macAddress);
      if (!device.isPresent()) {
        RotatingFileLogger.get().logw(TAG, "Cannot find the device " + macAddress +
            " when trying to start listening to its events.");
        uiThreadHandler.post(() ->
            eventSink.error(ERROR_DEVICE_NOT_FOUND, /*errorMessage=*/null,
                /*errorDetails=*/null));
        return;
      }
      deviceInternalStateListeners.put(macAddress, newDeviceInternalState ->
          uiThreadHandler.post(() -> eventSink.success(newDeviceInternalState)));
      device.get().addOnDeviceInternalStateChangeListener(
          deviceInternalStateListeners.get(macAddress));
    } else {
      RotatingFileLogger.get().logw(TAG,
          "Service not connected, cannot start monitoring internal device state.");
    }
  }

  private void stopListeningToDeviceEvents(String macAddress) {
    if (nextSenseServiceBound) {
      Optional<Device> device = nextSenseService.getDeviceManager().getDevice(macAddress);
      if (!device.isPresent()) {
        RotatingFileLogger.get().logw(TAG, "Cannot find the device " + macAddress +
            " when trying to stop listening to its events.");
        return;
      }
      NextSenseDevice.DeviceInternalStateChangeListener deviceInternalStateListener =
          deviceInternalStateListeners.get(macAddress);
      if (deviceInternalStateListener != null) {
        device.get().removeOnDeviceInternalStateChangeListener(deviceInternalStateListener);
        RotatingFileLogger.get().logi(TAG, "Stopped listening to Android device events for " +
            macAddress);
      }
    } else {
      RotatingFileLogger.get().logw(TAG,
          "Service not connected, cannot stop monitoring device events.");
    }
  }

  private void startListeningToInternalDeviceState(EventChannel.EventSink eventSink) {
    if (nextSenseServiceBound) {
      if (deviceInternalStateSubscription != null) {
        deviceInternalStateSubscription.cancel();
      }
      deviceInternalStateSubscription =
          nextSenseService.getObjectBoxDatabase().subscribe(
              DeviceInternalState.class, deviceInternalStateClass -> {
                List<DeviceInternalState> deviceInternalStates =
                    nextSenseService.getObjectBoxDatabase()
                        .getLastDeviceInternalStates(/*count=*/1);
                if (deviceInternalStates != null && !deviceInternalStates.isEmpty()) {
                  DeviceInternalState deviceInternalState = nextSenseService.getObjectBoxDatabase()
                      .getLastDeviceInternalStates(/*count=*/1).get(0);
                  eventSink.success(gson.toJson(deviceInternalState));
                }
              },
              deviceInternalStateSubscriptionScheduler);
    } else {
      RotatingFileLogger.get().logw(TAG, "Service not connected, cannot start monitoring internal device state.");
    }
  }

  private void stopListeningToInternalDeviceState() {
    if (deviceInternalStateSubscription != null) {
      deviceInternalStateSubscription.cancel();
      deviceInternalStateSubscription = null;
    }
  }

  private void starListeningToCurrentSessionDataReceived(EventChannel.EventSink eventSink) {
    if (nextSenseServiceBound) {
      LocalSessionManager localSessionManager = nextSenseService.getLocalSessionManager();
      onCurrentSessionDataReceivedListener =
          () -> uiThreadHandler.post(() -> eventSink.success(null));
      localSessionManager.addOnFirstDataReceivedListener(onCurrentSessionDataReceivedListener);
    } else {
      RotatingFileLogger.get().logw(TAG, "Service not connected, cannot start monitoring device state.");
    }
  }

  public void stopListeningToCurrentSessionDataReceived() {
    if (nextSenseServiceBound) {
      LocalSessionManager localSessionManager = nextSenseService.getLocalSessionManager();
      localSessionManager.removeOnFirstDataReceivedListener(onCurrentSessionDataReceivedListener);
    } else {
      RotatingFileLogger.get().logw(TAG, "Service not connected, cannot start monitoring device state.");
    }
  }

  private void connectDevice(Result result, String macAddress) {
    Optional<Device> device = nextSenseService.getDeviceManager().getDevice(macAddress);
    if (!device.isPresent()) {
      returnError(result, CONNECT_DEVICE_COMMAND, ERROR_DEVICE_NOT_FOUND, /*errorMessage=*/null,
          /*errorDetails=*/null);
      return;
    }
    try {
      DeviceState deviceState = device.get().connect(/*autoReconnect=*/true).get();
      if (deviceState == DeviceState.READY) {
        result.success(null);
      } else {
        returnError(result, CONNECT_DEVICE_COMMAND, CONNECT_TO_DEVICE_ERROR_CONNECTION,
            /*errorMessage=*/"Failed to connect.", /*errorDetails=*/null);
      }
    } catch (ExecutionException e) {
      returnError(result, CONNECT_DEVICE_COMMAND, CONNECT_TO_DEVICE_ERROR_CONNECTION,
          /*errorMessage=*/e.getMessage(), /*errorDetails=*/null);
    } catch (InterruptedException e) {
      returnError(result, CONNECT_DEVICE_COMMAND, CONNECT_TO_DEVICE_ERROR_INTERRUPTED,
          /*errorMessage=*/e.getMessage(), /*errorDetails=*/null);
      Thread.currentThread().interrupt();
    }
  }

  private void disconnectDevice(Result result, String macAddress) {
    Optional<Device> device = nextSenseService.getDeviceManager().getDevice(macAddress);
    if (!device.isPresent()) {
      returnError(result, DISCONNECT_DEVICE_COMMAND, ERROR_DEVICE_NOT_FOUND, /*errorMessage=*/null,
          /*errorDetails=*/null);
      return;
    }
    try {
      DeviceState deviceState = device.get().disconnect().get(3, TimeUnit.SECONDS);
      if (deviceState == DeviceState.DISCONNECTED) {
        result.success(true);
      } else {
        returnError(result, DISCONNECT_DEVICE_COMMAND, CONNECT_TO_DEVICE_ERROR_CONNECTION,
            /*errorMessage=*/"Failed to disconnect.", /*errorDetails=*/null);
      }
    } catch (ExecutionException e) {
      returnError(result, DISCONNECT_DEVICE_COMMAND, CONNECT_TO_DEVICE_ERROR_CONNECTION,
          /*errorMessage=*/e.getMessage(), /*errorDetails=*/null);
    } catch (InterruptedException e) {
      returnError(result, DISCONNECT_DEVICE_COMMAND, CONNECT_TO_DEVICE_ERROR_INTERRUPTED,
          /*errorMessage=*/e.getMessage(), /*errorDetails=*/null);
      Thread.currentThread().interrupt();
    } catch (TimeoutException e) {
      returnError(result, DISCONNECT_DEVICE_COMMAND, CONNECT_TO_DEVICE_ERROR_CONNECTION,
          /*errorMessage=*/"Timeout disconnecting", /*errorDetails=*/null);
    }
  }

  private void canStartNewSession(Result result) {
    result.success(nextSenseService.getLocalSessionManager().canStartNewSession());
  }

  private void startStreaming(
      Result result, String macAddress, Boolean uploadToCloud, String userBigTableKey,
      String dataSessionId, String earbudsConfig) {
    Optional<Device> device = nextSenseService.getDeviceManager().getDevice(macAddress);
    if (!device.isPresent()) {
      returnError(result, START_STREAMING_COMMAND, ERROR_DEVICE_NOT_FOUND, /*errorMessage=*/null,
          /*errorDetails=*/null);
      return;
    }
    try {
      // Clear the memory cache from the previous recording data, if any.
      nextSenseService.getMemoryCache().clear();
      boolean started = device.get().startStreaming(
          uploadToCloud, userBigTableKey, dataSessionId, earbudsConfig).get();
      if (!started) {
        returnError(result, START_STREAMING_COMMAND, ERROR_STREAMING_START_FAILED,
            /*errorMessage=*/null, /*errorDetails=*/null);
        return;
      }
    } catch (ExecutionException e) {
      returnError(result, START_STREAMING_COMMAND, ERROR_STREAMING_START_FAILED,
          /*errorMessage=*/e.getMessage(), /*errorDetails=*/null);
      return;
    } catch (InterruptedException e) {
      Thread.currentThread().interrupt();
      returnError(result, START_STREAMING_COMMAND, ERROR_STREAMING_START_FAILED,
          /*errorMessage=*/e.getMessage(), /*errorDetails=*/null);
      return;
    }
    Optional<LocalSession> localSession =
        nextSenseService.getLocalSessionManager().getActiveLocalSession();
    if (localSession.isPresent()) {
      result.success(localSession.get().id);
    } else {
      returnError(result, START_STREAMING_COMMAND, ERROR_SESSION_NOT_STARTED, /*errorMessage=*/null,
          /*errorDetails=*/null);
    }
  }

  private void stopStreaming(Result result, String macAddress) {
    Optional<Device> device = nextSenseService.getDeviceManager().getDevice(macAddress);
    if (!device.isPresent()) {
      returnError(result, STOP_STREAMING_COMMAND, ERROR_DEVICE_NOT_FOUND, /*errorMessage=*/null,
          /*errorDetails=*/null);
      return;
    }
    try {
      boolean stopped = device.get().stopStreaming().get();
      if (stopped) {
        result.success(null);
      } else {
        returnError(result, STOP_STREAMING_COMMAND, ERROR_STREAMING_STOP_FAILED,
            /*errorMessage=*/null, /*errorDetails=*/null);
      }
    } catch (ExecutionException e) {
      returnError(result, STOP_STREAMING_COMMAND, ERROR_STREAMING_STOP_FAILED,
          /*errorMessage=*/e.getMessage(), /*errorDetails=*/null);
    } catch (InterruptedException e) {
      Thread.currentThread().interrupt();
      returnError(result, STOP_STREAMING_COMMAND, ERROR_STREAMING_STOP_FAILED,
          /*errorMessage=*/e.getMessage(), /*errorDetails=*/null);
    }
  }

  private void isDeviceStreaming(Result result, String macAddress) {
    Optional<Device> device = nextSenseService.getDeviceManager().getDevice(macAddress);
    if (!device.isPresent()) {
      returnError(result, START_IMPEDANCE_COMMAND, ERROR_DEVICE_NOT_FOUND, /*errorMessage=*/null,
          /*errorDetails=*/null);
      return;
    }
    result.success(device.get().getMode() == DeviceMode.STREAMING);
  }

  private void startImpedance(
      Result result, String macAddress, String impedanceModeName, @Nullable Integer channelNumber,
      @Nullable Integer frequencyDivider) {
    Optional<Device> device = nextSenseService.getDeviceManager().getDevice(macAddress);
    if (!device.isPresent()) {
      returnError(result, START_IMPEDANCE_COMMAND, ERROR_DEVICE_NOT_FOUND, /*errorMessage=*/null,
          /*errorDetails=*/null);
      return;
    }
    ImpedanceMode impedanceMode = ImpedanceMode.valueOf(impedanceModeName);
    try {
      boolean started = device.get().startImpedance(
          impedanceMode, channelNumber, frequencyDivider).get();
      if (!started) {
        returnError(result, START_IMPEDANCE_COMMAND, ERROR_STREAMING_START_FAILED,
            /*errorMessage=*/null, /*errorDetails=*/null);
        return;
      }
    } catch (ExecutionException e) {
      returnError(result, START_IMPEDANCE_COMMAND, ERROR_STREAMING_START_FAILED,
          /*errorMessage=*/e.getMessage(), /*errorDetails=*/null);
      return;
    } catch (InterruptedException e) {
      Thread.currentThread().interrupt();
      returnError(result, START_IMPEDANCE_COMMAND, ERROR_STREAMING_START_FAILED,
          /*errorMessage=*/e.getMessage(), /*errorDetails=*/null);
      return;
    }
    Optional<LocalSession> localSession =
        nextSenseService.getLocalSessionManager().getActiveLocalSession();
    if (localSession.isPresent()) {
      RotatingFileLogger.get().logi(TAG, "start impedance returning local session " + localSession.get().id);
      result.success(localSession.get().id);
    } else {
      returnError(result, START_IMPEDANCE_COMMAND, ERROR_SESSION_NOT_STARTED,
          /*errorMessage=*/null, /*errorDetails=*/null);
    }
  }

  private void setImpedanceConfig(
      Result result, String macAddress, String impedanceModeName, @Nullable Integer channelNumber,
      @Nullable Integer frequencyDivider) {
    Optional<Device> device = nextSenseService.getDeviceManager().getDevice(macAddress);
    if (!device.isPresent()) {
      returnError(result, SET_IMPEDANCE_CONFIG_COMMAND, ERROR_DEVICE_NOT_FOUND,
          /*errorMessage=*/null, /*errorDetails=*/null);
      return;
    }
    ImpedanceMode impedanceMode = ImpedanceMode.valueOf(impedanceModeName);
    try {
      boolean configured =
          device.get().setImpedanceConfig(impedanceMode, channelNumber, frequencyDivider).get();
      if (!configured) {
        returnError(result, SET_IMPEDANCE_CONFIG_COMMAND, ERROR_STREAMING_START_FAILED,
            /*errorMessage=*/null, /*errorDetails=*/null);
      }
      result.success(true);
    } catch (ExecutionException e) {
      returnError(result, SET_IMPEDANCE_CONFIG_COMMAND, ERROR_STREAMING_START_FAILED,
          /*errorMessage=*/e.getMessage(), /*errorDetails=*/null);
    } catch (InterruptedException e) {
      Thread.currentThread().interrupt();
      returnError(result, SET_IMPEDANCE_CONFIG_COMMAND, ERROR_STREAMING_START_FAILED,
          /*errorMessage=*/e.getMessage(), /*errorDetails=*/null);
    }
  }

  private void stopImpedance(Result result, String macAddress) {
    Optional<Device> device = nextSenseService.getDeviceManager().getDevice(macAddress);
    if (!device.isPresent()) {
      returnError(result, STOP_IMPEDANCE_COMMAND, ERROR_DEVICE_NOT_FOUND, /*errorMessage=*/null,
          /*errorDetails=*/null);
      return;
    }
    try {
      boolean stopped = device.get().stopImpedance().get();
      result.success(stopped);
    } catch (ExecutionException e) {
      returnError(result, STOP_IMPEDANCE_COMMAND, ERROR_STREAMING_STOP_FAILED,
          /*errorMessage=*/e.getMessage(), /*errorDetails=*/null);
    } catch (InterruptedException e) {
      Thread.currentThread().interrupt();
      returnError(result, STOP_IMPEDANCE_COMMAND, ERROR_STREAMING_STOP_FAILED,
          /*errorMessage=*/e.getMessage(), /*errorDetails=*/null);
    }
  }

  private void getDeviceInfo(Result result, String macAddress) {
    Optional<Device> device = nextSenseService.getDeviceManager().getDevice(macAddress);
    if (!device.isPresent()) {
      returnError(result, GET_DEVICE_INFO_COMMAND, ERROR_DEVICE_NOT_FOUND,
          /*errorMessage=*/null, /*errorDetails=*/null);
      return;
    }
    DeviceInfo deviceInfo = device.get().getInfo();
    result.success(gson.toJson(deviceInfo));
  }

  private void getDeviceSettings(Result result, String macAddress) {
    Optional<Device> device = nextSenseService.getDeviceManager().getDevice(macAddress);
    if (!device.isPresent()) {
      returnError(result, GET_DEVICE_SETTINGS_COMMAND, ERROR_DEVICE_NOT_FOUND,
          /*errorMessage=*/null, /*errorDetails=*/null);
      return;
    }
    result.success(gson.toJson(device.get().getSettings()));
  }

  private void getChannelData(
      Result result, String macAddress, Integer localSessionId, String channelName,
      Integer durationMillis, Boolean fromDatabase) {
    Optional<Device> device = nextSenseService.getDeviceManager().getDevice(macAddress);
    if (!device.isPresent()) {
      returnError(result, GET_CHANNEL_DATA_COMMAND, ERROR_DEVICE_NOT_FOUND, /*errorMessage=*/null,
          /*errorDetails=*/null);
      return;
    }
    if (fromDatabase != null && fromDatabase) {
      result.success(nextSenseService.getObjectBoxDatabase().getLastChannelData(
              localSessionId, channelName, Duration.ofMillis(durationMillis)));
    } else {
      int numberOfSamples = (int) Math.round(Math.ceil(
          (float) durationMillis / Math.round(1000f /
              device.get().getSettings().getEegStreamingRate())));
      result.success(nextSenseService.getMemoryCache().getLastEegChannelData(
              channelName, numberOfSamples));
    }
  }

  private void getAccChannelData(
      Result result, String macAddress, Integer localSessionId, String channelName,
      Integer durationMillis, Boolean fromDatabase) {
    Optional<Device> device = nextSenseService.getDeviceManager().getDevice(macAddress);
    if (!device.isPresent()) {
      returnError(result, GET_ACC_CHANNEL_DATA_COMMAND, ERROR_DEVICE_NOT_FOUND, /*errorMessage=*/null,
          /*errorDetails=*/null);
      return;
    }
    if (fromDatabase != null && fromDatabase) {
      result.success(nextSenseService.getObjectBoxDatabase().getLastChannelData(
          localSessionId, channelName, Duration.ofMillis(durationMillis)));
    } else {
      int numberOfSamples = (int) Math.round(Math.ceil(
          (float) durationMillis / Math.round(1000f /
              device.get().getSettings().getImuStreamingRate())));
      result.success(nextSenseService.getMemoryCache().getLastAccChannelData(
          channelName, numberOfSamples));
    }
  }

  private void getTimestampsData(Result result, String macAddress, int durationMillis) {
    Optional<Device> device = nextSenseService.getDeviceManager().getDevice(macAddress);
    if (!device.isPresent()) {
      returnError(result, GET_TIMESTAMPS_DATA_COMMAND, ERROR_DEVICE_NOT_FOUND,
          /*errorMessage=*/null, /*errorDetails=*/null);
      return;
    }
    int numberOfSamples = (int) Math.round(Math.ceil(
        (float) durationMillis / Math.round(1000f /
            device.get().getSettings().getEegStreamingRate())));
    result.success(nextSenseService.getMemoryCache().getLastTimestamps(numberOfSamples));
  }

  private void runSleepStaging(
      Result result, String macAddress, Integer localSessionId, String channelName,
      Instant startDateTime, Integer durationMillis, Boolean fromDatabase) {
    Optional<Device> device = nextSenseService.getDeviceManager().getDevice(macAddress);
    if (!device.isPresent()) {
      returnError(result, GET_CHANNEL_DATA_COMMAND, ERROR_DEVICE_NOT_FOUND, /*errorMessage=*/null,
          /*errorDetails=*/null);
      return;
    }
    List<Float> data;
    float eegSamplingRate = device.get().getSettings().getEegStreamingRate();
    if (fromDatabase != null && fromDatabase) {
      LocalSession localSession = nextSenseService.getObjectBoxDatabase().getLocalSession(
          localSessionId);
      int eegOffset = (int) Math.round(Math.ceil(
          (float) (startDateTime.toEpochMilli() - localSession.getStartTime().toEpochMilli()) /
              Math.round(1000f / eegSamplingRate)));
      long relativeEegOffset = eegOffset - localSession.getEegSamplesDeleted();
      data = nextSenseService.getObjectBoxDatabase().getChannelData(
          localSessionId, channelName, relativeEegOffset,
          durationMillis / Math.round(1000f / eegSamplingRate));
    } else {
      int numberOfSamples = (int) Math.round(Math.ceil(
          (float) durationMillis / Math.round(1000f / eegSamplingRate)));
      data = nextSenseService.getMemoryCache().getLastEegChannelData(
          channelName, numberOfSamples);
    }
    if (data != null && !data.isEmpty()) {
      Map<Integer, Object> results = nextSenseService.getSleepTransformerModel().doInference(data,
          device.get().getSettings().getEegStreamingRate());
      result.success(gson.toJson(results));
    } else {
      result.success(null);
    }
  }

  private void getDeviceInternalStateData(
      Result result, String macAddress, @Nullable Integer localSessionId, int durationMillis) {
    Optional<Device> device = nextSenseService.getDeviceManager().getDevice(macAddress);
    if (!device.isPresent()) {
      returnError(result, GET_DEVICE_INTERNAL_STATE_DATA_COMMAND, ERROR_DEVICE_NOT_FOUND,
          /*errorMessage=*/null, /*errorDetails=*/null);
      return;
    }
    if (localSessionId == null) {
      result.success(nextSenseService.getObjectBoxDatabase().getRecentDeviceInternalStateData(
          Duration.ofMillis(durationMillis)));
    }
  }

  private void deleteLocalSession(Result result, Integer localSessionId) {
    result.success(nextSenseService.getObjectBoxDatabase().deleteLocalSession(localSessionId));
  }

  private void setUploaderMinimumConnectivity(Result result, String connectionType) {
    if (nextSenseServiceBound) {
      Connectivity.State minConnectivityState = connectionType.equals("mobile") ?
          Connectivity.State.LIMITED_CONNECTION : Connectivity.State.FULL_CONNECTION;
      nextSenseService.getUploader().setMinimumConnectivityState(minConnectivityState);
      result.success(null);
    } else {
      result.error(ERROR_SERVICE_NOT_AVAILABLE, null, null);
    }
  }

  private void getFreeDiskSpace(Result result) {
    StatFs stat = new StatFs(Environment.getExternalStorageDirectory().getPath());
    long bytesAvailable;
    bytesAvailable = stat.getBlockSizeLong() * stat.getAvailableBlocksLong();
    result.success(bytesAvailable / (1024f * 1024f));
  }

  private void getTimezoneId(Result result) {
    String timeZone = TimeZone.getDefault().getID();
    result.success(timeZone);
  }

  private void getNativeLogs(Result result) {
    result.success(RotatingFileLogger.get().getAtLeast24HoursLogs());
  }

  private void returnError(
      Result result, String method, String errorCode, @Nullable String errorMessage,
      @Nullable String errorDetails) {
    String errorLog = "Error in " + method + ", code: " + errorCode;
    if (errorMessage != null) {
      errorLog += ", message: " + errorMessage;
    }
    if (errorDetails != null) {
      errorLog += ", details: " + errorDetails;
    }
    RotatingFileLogger.get().loge(TAG, errorLog);
    result.error(errorCode, errorMessage, errorDetails);
  }

  private final ServiceConnection nextSenseConnection = new ServiceConnection() {

    @Override
    public void onServiceConnected(ComponentName className,
                                   IBinder service) {
      // We've bound to LocalService, cast the IBinder and get LocalService instance
      ForegroundService.LocalBinder binder = (ForegroundService.LocalBinder) service;
      nextSenseService = binder.getService();
      nextSenseServiceBound = true;
      nextSenseService.setFlutterActivityActive(true);
    }

    @Override
    public void onServiceDisconnected(ComponentName componentName) {
      nextSenseServiceBound = false;
    }
  };
}
