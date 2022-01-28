package io.nextsense.flutter.base.nextsense_base;

import android.bluetooth.BluetoothAdapter;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;

import com.google.common.collect.Maps;
import com.google.gson.Gson;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.nextsense.android.base.Device;
import io.nextsense.android.base.DeviceScanner;
import io.nextsense.android.base.DeviceState;
import io.nextsense.android.service.ForegroundService;

/** NextSenseBasePlugin */
public class NextsenseBasePlugin implements FlutterPlugin, MethodCallHandler {
  public static final String CONNECT_TO_SERVICE_COMMAND = "connect_to_service";
  public static final String STOP_SERVICE_COMMAND = "stop_service";
  public static final String SET_FLUTTER_ACTIVITY_ACTIVE_COMMAND = "set_flutter_activity_active";
  public static final String IS_FLUTTER_ACTIVITY_ACTIVE_COMMAND = "is_flutter_activity_active";
  public static final String CONNECT_DEVICE_COMMAND = "connect_device";
  public static final String DISCONNECT_DEVICE_COMMAND = "disconnect_device";
  public static final String START_STREAMING_COMMAND = "start_streaming";
  public static final String STOP_STREAMING_COMMAND = "stop_streaming";
  public static final String GET_CONNECTED_DEVICES_COMMAND = "get_connected_devices";
  public static final String IS_BLUETOOTH_ENABLED = "is_bluetooth_enabled";
  public static final String MAC_ADDRESS_ARGUMENT = "mac_address";
  public static final String USER_BT_KEY_ARGUMENT = "user_bigtable_key";
  public static final String DATA_SESSION_ID_ARGUMENT = "data_session_id";
  public static final String ERROR_DEVICE_NOT_FOUND = "not_found";
  public static final String CONNECT_TO_DEVICE_ERROR_CONNECTION = "connection_error";
  public static final String CONNECT_TO_DEVICE_ERROR_INTERRUPTED = "connection_interrupted";

  private static final String TAG = NextsenseBasePlugin.class.getSimpleName();
  private static final String METHOD_CHANNEL_NAME = "nextsense_base";
  private static final String DEVICE_SCAN_CHANNEL_NAME =
      "io.nextsense.flutter.base.nextsense_base/device_scan_channel";
  private static final String DEVICE_STATE_CHANNEL_NAME =
      "io.nextsense.flutter.base.nextsense_base/device_state_channel";

  // Handler for the UI thread which is needed for running flutter JNI methods.
  private final Handler uiThreadHandler = new Handler(Looper.getMainLooper());
  private final Gson gson = new Gson();
  private final Map<String, Device> devices = Maps.newConcurrentMap();
  private final Map<String, Device.DeviceStateChangeListener> deviceStateListeners =
      Maps.newConcurrentMap();
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel methodChannel;
  private EventChannel deviceScanChannel;
  private EventChannel deviceStateChannel;
  private Context applicationContext;
  private Intent foregroundServiceIntent;
  private ForegroundService nextSenseService;
  private boolean nextSenseServiceBound = false;
  private DeviceScanner.DeviceScanListener deviceScanListener;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    Log.i(TAG, "Attaching to engine.");
    methodChannel =
        new MethodChannel(flutterPluginBinding.getBinaryMessenger(), METHOD_CHANNEL_NAME);
    methodChannel.setMethodCallHandler(this);
    Log.i(TAG, "Getting context.");
    applicationContext = flutterPluginBinding.getApplicationContext();
    deviceScanChannel =
        new EventChannel(flutterPluginBinding.getBinaryMessenger(), DEVICE_SCAN_CHANNEL_NAME);
    deviceScanChannel.setStreamHandler(new EventChannel.StreamHandler() {
      @Override
      public void onListen(Object listener, EventChannel.EventSink eventSink) {
        Log.i(TAG, "Starting Android Bluetooth scan...");
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
      public void onListen(Object arguments, EventChannel.EventSink eventSink) {
        Log.i(TAG, "Starting to listen to Android device state...");
        List<Object> argumentList = (ArrayList<Object>) arguments;
        startListeningToDeviceState(eventSink, (String) argumentList.get(1));
      }
      @Override
      public void onCancel(Object arguments) {
        List<Object> argumentList = (ArrayList<Object>) arguments;
        stopListeningToDeviceState((String) argumentList.get(1));
      }
    });
    Log.i(TAG, "Attached to engine.");
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method) {
      case "getPlatformVersion":
        result.success("Android " + android.os.Build.VERSION.RELEASE);
        break;
      case CONNECT_TO_SERVICE_COMMAND:
        connectToService();
        break;
      case STOP_SERVICE_COMMAND:
        stopService();
        break;
      case CONNECT_DEVICE_COMMAND:
        String macAddress = call.argument(MAC_ADDRESS_ARGUMENT);
        Log.d(TAG, "connecting to device: " + macAddress);
        connectDevice(result, macAddress);
        Log.d(TAG, "connected to device: " + macAddress + " with result " + result.toString());
        break;
      case DISCONNECT_DEVICE_COMMAND:
        macAddress = call.argument(MAC_ADDRESS_ARGUMENT);
        Log.d(TAG, "disconnecting from device: " + macAddress);
        disconnectDevice(result, macAddress);
        Log.d(TAG, "disconnected from device: " + macAddress + " with result " +
            result.toString());
        break;
      case IS_BLUETOOTH_ENABLED:
        result.success(BluetoothAdapter.getDefaultAdapter().isEnabled());
        break;
      case START_STREAMING_COMMAND:
        macAddress = call.argument(MAC_ADDRESS_ARGUMENT);
        String user_bt_key = call.argument(USER_BT_KEY_ARGUMENT);
        String data_session_id = call.argument(DATA_SESSION_ID_ARGUMENT);
        startStreaming(result, macAddress, user_bt_key, data_session_id);
        break;
      case STOP_STREAMING_COMMAND:
        macAddress = call.argument(MAC_ADDRESS_ARGUMENT);
        stopStreaming(result, macAddress);
        break;
      case GET_CONNECTED_DEVICES_COMMAND:
        getConnectedDevices(result);
        break;
      case SET_FLUTTER_ACTIVITY_ACTIVE_COMMAND:
        if (nextSenseServiceBound) {
          nextSenseService.setFlutterActivityActive((boolean)call.arguments);
        } else {
          Log.d(TAG, "flutter_start: service not connected.");
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

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    methodChannel.setMethodCallHandler(null);
    deviceScanChannel.setStreamHandler(null);
    applicationContext = null;
    Log.i(TAG, "Detached from engine.");
  }

  private void connectToService() {
    if (applicationContext != null) {
      try {
        Class<?> uiClass = Class.forName(
            "io.flutter.embedding.android.FlutterActivity");
        Log.i(TAG, "Creating intent.");
        foregroundServiceIntent = new Intent(applicationContext, ForegroundService.class);
        foregroundServiceIntent.putExtra("ui_class", uiClass);
        applicationContext.startService(foregroundServiceIntent);
        applicationContext.bindService(foregroundServiceIntent, nextSenseConnection,
            Context.BIND_IMPORTANT);
      } catch (ClassNotFoundException e) {
        Log.e(TAG, "Could not find class: " +
            "io.flutter.embedding.android.FlutterActivity");
      }
    } else {
      Log.d(TAG, "context still null");
    }
  }

  private void stopService() {
    if (applicationContext != null) {
      applicationContext.stopService(foregroundServiceIntent);
    } else {
      Log.d(TAG, "context still null");
    }
  }

  private void getConnectedDevices(Result result) {
    List<String> connectedDevicesJson = new ArrayList<>();
    if (nextSenseServiceBound) {
      List<Device> connectedDevices = nextSenseService.getDeviceManager().getConnectedDevices();
      for (Device device : connectedDevices) {
        connectedDevicesJson.add(
            gson.toJson(new DeviceAttributes(device.getAddress(), device.getName())));
      }
    }
    result.success(connectedDevicesJson);
  }

  private void startScanning(EventChannel.EventSink eventSink) {
    if (nextSenseServiceBound) {
      deviceScanListener = new DeviceScanner.DeviceScanListener() {
        @Override
        public void onNewDevice(Device device) {
          Log.i(TAG, "Found a device in Android scan: " + device.getName());
          devices.put(device.getAddress(), device);
          DeviceAttributes deviceAttributes =
              new DeviceAttributes(device.getAddress(), device.getName());
          uiThreadHandler.post(() -> eventSink.success(gson.toJson(deviceAttributes)));
        }

        @Override
        public void onScanError(ScanError scanError) {
          Log.e(TAG, "Error while scanning in Android: " + scanError.name());
          uiThreadHandler.post(() ->
              eventSink.error(scanError.name(), scanError.name(), scanError.name()));
        }
      };
      nextSenseService.getDeviceManager().findDevices(deviceScanListener);
    } else {
      Log.w(TAG, "Service not connected, cannot start Bluetooth scan.");
    }
  }

  private void stopScanning() {
    if (nextSenseServiceBound && deviceScanListener != null) {
      nextSenseService.getDeviceManager().stopFindingDevices(deviceScanListener);
      deviceScanListener = null;
    } else {
      Log.d(TAG, "Service not connected.");
    }
  }

  private void startListeningToDeviceState(EventChannel.EventSink eventSink, String macAddress) {
    if (nextSenseServiceBound) {
      Device device = devices.get(macAddress);
      if (device == null) {
        uiThreadHandler.post(() ->
            eventSink.error(ERROR_DEVICE_NOT_FOUND, /*errorMessage=*/null,
                /*errorDetails=*/null));
        return;
      }
      deviceStateListeners.put(macAddress, newDeviceState ->
          uiThreadHandler.post(() -> eventSink.success(newDeviceState.name())));
      device.addOnDeviceStateChangeListener(deviceStateListeners.get(macAddress));
    } else {
      Log.w(TAG, "Service not connected, cannot start monitoring device state.");
    }
  }

  public void stopListeningToDeviceState(String macAddress) {
    if (nextSenseServiceBound) {
      Device device = devices.get(macAddress);
      if (device == null) {
        Log.w(TAG, "Cannot find the device " + macAddress +
            " when trying to stop listening to its state.");
        return;
      }
      Device.DeviceStateChangeListener deviceStateListener = deviceStateListeners.get(macAddress);
      if (deviceStateListener != null) {
        device.removeOnDeviceStateChangeListener(deviceStateListener);
        Log.i(TAG, "Stopped listening to Android device state for " + macAddress);
      }
    } else {
      Log.w(TAG, "Service not connected, cannot start monitoring device state.");
    }
  }

  private void connectDevice(Result result, String macAddress) {
    Device device = devices.get(macAddress);
    if (device == null) {
      result.error(ERROR_DEVICE_NOT_FOUND, /*errorMessage=*/null,
          /*errorDetails=*/null);
      return;
    }
    try {
      DeviceState deviceState = device.connect(/*autoReconnect=*/true).get();
      if (deviceState == DeviceState.READY) {
        result.success(null);
      } else {
        result.error(CONNECT_TO_DEVICE_ERROR_CONNECTION, /*errorMessage=*/"Failed to connect.",
            /*errorDetails=*/null);
      }
    } catch (ExecutionException e) {
      result.error(CONNECT_TO_DEVICE_ERROR_CONNECTION, /*errorMessage=*/e.getMessage(),
          /*errorDetails=*/e);
    } catch (InterruptedException e) {
      result.error(CONNECT_TO_DEVICE_ERROR_INTERRUPTED, /*errorMessage=*/e.getMessage(),
          /*errorDetails=*/e);
      Thread.currentThread().interrupt();
    }
  }

  private void disconnectDevice(Result result, String macAddress) {
    Device device = devices.get(macAddress);
    if (device == null) {
      result.error(ERROR_DEVICE_NOT_FOUND, /*errorMessage=*/null,
          /*errorDetails=*/null);
      return;
    }
    try {
      DeviceState deviceState = device.disconnect().get();
      if (deviceState == DeviceState.DISCONNECTED) {
        result.success(null);
      } else {
        result.error(CONNECT_TO_DEVICE_ERROR_CONNECTION, /*errorMessage=*/"Failed to disconnect.",
            /*errorDetails=*/null);
      }
    } catch (ExecutionException e) {
      result.error(CONNECT_TO_DEVICE_ERROR_CONNECTION, /*errorMessage=*/e.getMessage(),
          /*errorDetails=*/e);
    } catch (InterruptedException e) {
      result.error(CONNECT_TO_DEVICE_ERROR_INTERRUPTED, /*errorMessage=*/e.getMessage(),
          /*errorDetails=*/e);
      Thread.currentThread().interrupt();
    }
  }

  private void startStreaming(Result result, String macAddress, String userBigTableKey,
                              String dataSessionId) {
    Device device = devices.get(macAddress);
    if (device == null) {
      result.error(ERROR_DEVICE_NOT_FOUND, /*errorMessage=*/null,
          /*errorDetails=*/null);
      return;
    }
    device.startStreaming(userBigTableKey, dataSessionId);
  }

  private void stopStreaming(Result result, String macAddress) {
    Device device = devices.get(macAddress);
    if (device == null) {
      result.error(ERROR_DEVICE_NOT_FOUND, /*errorMessage=*/null,
          /*errorDetails=*/null);
      return;
    }
    device.stopStreaming();
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
