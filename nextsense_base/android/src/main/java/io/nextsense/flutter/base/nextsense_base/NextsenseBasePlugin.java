package io.nextsense.flutter.base.nextsense_base;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.IBinder;
import android.util.Log;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.nextsense.android.base.DeviceManager;
import io.nextsense.android.service.ForegroundService;

/** NextSenseBasePlugin */
public class NextsenseBasePlugin implements FlutterPlugin, MethodCallHandler {
  public static final String CONNECT_TO_SERVICE_COMMAND = "connectToService";
  private static final String TAG = NextsenseBasePlugin.class.getSimpleName();

  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;
  private Context applicationContext;
  private Intent foregroundServiceIntent;
  private ForegroundService nextSenseService;
  private boolean nextSenseServiceBound = false;
  private DeviceManager deviceManager;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    Log.i(TAG, "Attaching to engine.");
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "nextsense_base");
    channel.setMethodCallHandler(this);
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
    channel.setMethodCallHandler(null);
  }

  private final ServiceConnection nextSenseConnection = new ServiceConnection() {

    @Override
    public void onServiceConnected(ComponentName className,
                                   IBinder service) {
      // We've bound to LocalService, cast the IBinder and get LocalService instance
      ForegroundService.LocalBinder binder = (ForegroundService.LocalBinder) service;
      nextSenseService = binder.getService();
      deviceManager = nextSenseService.getDeviceManager();
      // nextSenseService.getSampleRateCalculator().addRateUpdateListener(rateUpdateListener);
      nextSenseServiceBound = true;
      nextSenseService.setFlutterActivityActive(true);
    }

    @Override
    public void onServiceDisconnected(ComponentName componentName) {
      nextSenseServiceBound = false;
    }
  };
}
