package io.nextsense.flutter.base.nextsense_base;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.IBinder;
import android.util.Log;

import androidx.annotation.NonNull;

import com.google.gson.Gson;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.nextsense.android.base.Device;
import io.nextsense.android.base.DeviceScanner;
import io.nextsense.android.service.ForegroundService;

/** NextSenseBasePlugin */
public class NextsenseBasePlugin implements FlutterPlugin, MethodCallHandler {
  public static final String CONNECT_TO_SERVICE_COMMAND = "connect_to_service";
  public static final String START_SCANNING_COMMAND = "start_scanning";

  private static final String TAG = NextsenseBasePlugin.class.getSimpleName();
  private static final String METHOD_CHANNEL_NAME = "nextsense_base";
  private static final String DEVICE_SCAN_CHANNEL_NAME = "device_scan_channel";

  private final Gson gson = new Gson();
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel methodChannel;
  private EventChannel deviceScanChannel;
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
    deviceScanChannel =
        new EventChannel(flutterPluginBinding.getBinaryMessenger(), DEVICE_SCAN_CHANNEL_NAME);
    deviceScanChannel.setStreamHandler(new EventChannel.StreamHandler() {
      @Override
      public void onListen(Object listener, EventChannel.EventSink eventSink) {
        startScanning(eventSink);
      }
      @Override
      public void onCancel(Object listener) {
        stopScanning();
      }
    });
    Log.i(TAG, "Getting context.");
    applicationContext = flutterPluginBinding.getApplicationContext();
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
      case "test":
        if (nextSenseServiceBound) {
          Log.d(TAG, "connected devices: " +
              nextSenseService.getDeviceManager().getConnectedDevices().size());
          result.success(nextSenseService.getDeviceManager().getConnectedDevices().size());
        } else {
          Log.d(TAG, "Service not connected.");
        }
        break;
      case "set_flutter_activity_active":
        if (nextSenseServiceBound) {
          nextSenseService.setFlutterActivityActive((boolean)call.arguments);
        } else {
          Log.d(TAG, "flutter_start: service not connected.");
        }
        break;
      case "is_flutter_activity_active":
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

  private void startScanning(EventChannel.EventSink eventSink) {
    if (nextSenseServiceBound) {
      deviceScanListener = new DeviceScanner.DeviceScanListener() {
        @Override
        public void onNewDevice(Device device) {
          DeviceAttributes deviceAttributes =
              new DeviceAttributes(device.getAddress(), device.getName());
          eventSink.success(gson.toJson(deviceAttributes));
        }

        @Override
        public void onScanError(ScanError scanError) {
          eventSink.error(scanError.name(), scanError.name(), scanError.name());
        }
      };
      nextSenseService.getDeviceManager().findDevices(deviceScanListener);
    } else {
      Log.d(TAG, "Service not connected.");
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
