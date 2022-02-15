package io.nextsense.android.baselibrarytestui;

import androidx.appcompat.app.AppCompatActivity;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.IBinder;
import android.util.Log;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterEngineCache;
import io.nextsense.android.service.ForegroundService;

/**
 * Main Android Activity for the application. Hosts the Flutter activity and manages the Flutter
 * and service life cycles.
 */
public class MainActivity extends AppCompatActivity {

  private static final String TAG = MainActivity.class.getSimpleName();
  private static final boolean AUTOSTART_FLUTTER = true;

  private Intent foregroundServiceIntent;
  private ForegroundService nextSenseService;
  private boolean nextSenseServiceBound = false;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_main);
    foregroundServiceIntent = new Intent(getApplicationContext(), ForegroundService.class);
    foregroundServiceIntent.putExtra("ui_class", MainActivity.class);

    // Need to start the service explicitly so that 'onStartCommand' gets called in the service.
    getApplicationContext().startService(foregroundServiceIntent);

    Log.d(TAG, "started");
  }

  @Override
  protected void onStart() {
    super.onStart();
    if (!nextSenseServiceBound) {
      bindService(foregroundServiceIntent, nextSenseConnection, Context.BIND_IMPORTANT);
    } else {
      Log.i(TAG, "service bound. Flutter active: " +
          nextSenseService.isFlutterActivityActive());
      if (AUTOSTART_FLUTTER) {
        if (nextSenseService.isFlutterActivityActive()) {
          startFlutter();
        } else {
          stopService();
          finish();
        }
      }
    }
  }

  @Override
  protected void onStop() {
    if (nextSenseServiceBound) {
      unbindService(nextSenseConnection);
      nextSenseServiceBound = false;
    }
    super.onStop();
  }

  @Override
  public void onBackPressed() {
    // Should add a confirmation prompt here in a non-test app.
    stopService();
    super.onBackPressed();
  }

  @Override
  public void onDestroy() {
    super.onDestroy();
    // The flutter engine would survive the application.
    FlutterEngine flutterEngine = FlutterEngineCache.getInstance().get(TestUi.FLUTTER_ENGINE_NAME);
    if (flutterEngine != null) {
      Log.i(TAG, "Detaching flutter engine.");
      flutterEngine.getPlatformViewsController().detachFromView();
      flutterEngine.getLifecycleChannel().appIsDetached();
      FlutterEngineCache.getInstance().remove(TestUi.FLUTTER_ENGINE_NAME);
    }
  }

  private void stopService() {
    stopService(foregroundServiceIntent);
  }

  private void startFlutter() {
    if (FlutterEngineCache.getInstance().get(TestUi.FLUTTER_ENGINE_NAME) == null) {
      ((TestUi) getApplicationContext()).initFlutterEngineCache();
    }
    startActivity(FlutterActivity.withCachedEngine(TestUi.FLUTTER_ENGINE_NAME)
        .build(this));
  }

  private final ServiceConnection nextSenseConnection = new ServiceConnection() {

    @Override
    public void onServiceConnected(ComponentName className,
                                   IBinder service) {
      // We've bound to LocalService, cast the IBinder and get LocalService instance
      ForegroundService.LocalBinder binder = (ForegroundService.LocalBinder) service;
      nextSenseService = binder.getService();
      nextSenseServiceBound = true;
      Log.i(TAG, "service bound. Flutter active: " +
          nextSenseService.isFlutterActivityActive());
      if (AUTOSTART_FLUTTER) {
        if (nextSenseService.isFlutterActivityActive()) {
          startFlutter();
        } else {
          stopService();
          finish();
        }
      }
    }

    @Override
    public void onServiceDisconnected(ComponentName componentName) {
      nextSenseServiceBound = false;
      nextSenseService = null;
    }
  };
}