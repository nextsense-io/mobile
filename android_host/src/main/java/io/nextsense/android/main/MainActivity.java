package io.nextsense.android.main;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.os.IBinder;
import android.util.Log;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import java.util.Map;

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
  // This value cannot be changed so that the flutter plugin refers to the same preference file. See
  // https://github.com/flutter/plugins/blob/main/packages/shared_preferences/shared_preferences_android/android/src/main/java/io/flutter/plugins/sharedpreferences/MethodCallHandlerImpl.java
  private static final String SHARED_PREF_FILE_KEY =
          "FlutterSharedPreferences";
  // Needs to add "flutter." as a prefix to the key that is retrieved on the flutter side. This is
  // silently added to keys that are saved by the flutter plugin. See
  // https://github.com/flutter/plugins/blob/main/packages/shared_preferences/shared_preferences/lib/shared_preferences.dart
  private static final String FLUTTER_PREF_PREFIX = "flutter.";
  private static final String FLAVOR_PREF_KEY = "flavor";

  // Awesome notifications Json payload constants.
  private static final String EXTRA_NOTIFICATION_JSON = "notificationJson";
  private static final String JSON_KEY_CONTENT = "content";
  private static final String JSON_KEY_PAYLOAD = "payload";

  // Custom scheme Json elements for navigation.
  enum NavigationTarget {
    PROTOCOL,
    SURVEY
  }

  private final GsonBuilder gsonBuilder = new GsonBuilder();
  private final Gson gson = gsonBuilder.create();

  private Intent foregroundServiceIntent;
  private ForegroundService nextSenseService;
  private boolean nextSenseServiceBound = false;
  private Intent initialIntent;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);

    Log.i(TAG, "Start intent received: " + getIntent().toString());
    if (getIntent().getExtras() != null) {
      Log.i(TAG, "Start intent received extras: " + getIntent().getExtras().toString());
      Log.i(TAG, "Start intent received json: " +
              getIntent().getExtras().get(EXTRA_NOTIFICATION_JSON));
      initialIntent = getIntent();
    }

    setContentView(R.layout.activity_main);

    SharedPreferences sharedPref = getSharedPreferences(SHARED_PREF_FILE_KEY, Context.MODE_PRIVATE);
    SharedPreferences.Editor editor = sharedPref.edit();
    editor.putString(FLUTTER_PREF_PREFIX + FLAVOR_PREF_KEY, BuildConfig.FLAVOR);
    editor.apply();

    foregroundServiceIntent = new Intent(getApplicationContext(), ForegroundService.class);
    foregroundServiceIntent.putExtra(ForegroundService.EXTRA_UI_CLASS, MainActivity.class);
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
          startFlutter(initialIntent);
          initialIntent = null;
        } else {
          stopService();
          finish();
        }
      }
    }
  }

  @Override
  @SuppressWarnings("unchecked")
  protected void onNewIntent(Intent intent) {
    super.onNewIntent(intent);
    Log.i(TAG, "New intent received: " + intent.toString());
    if (intent.getExtras() != null) {
      Log.i(TAG, "New intent received extras: " + intent.getExtras().toString());
      String jsonData = intent.getExtras().getString(EXTRA_NOTIFICATION_JSON);
      if (jsonData != null) {
        Map notificationData = gson.fromJson(jsonData, Map.class);
        Map contentMap = (Map) notificationData.get(JSON_KEY_CONTENT);
        if (contentMap == null) {
          return;
        }
        Map<String, String> payloadMap = (Map<String, String>) contentMap.get(JSON_KEY_PAYLOAD);
        if (payloadMap == null) {
          return;
        }
        boolean validTarget = false;
        for (NavigationTarget target : NavigationTarget.values()) {
          if (payloadMap.containsKey(target.name().toLowerCase())) {
            validTarget = true;
          }
        }
        if (validTarget) {
          // There is an notification JSON, so start Flutter so it can navigate to the screen in the
          // payload.
          startFlutter(intent);
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
    FlutterEngine flutterEngine =
            FlutterEngineCache.getInstance().get(NextSenseApplication.FLUTTER_ENGINE_NAME);
    if (flutterEngine != null) {
      Log.i(TAG, "Detaching flutter engine.");
      flutterEngine.getPlatformViewsController().detachFromView();
      flutterEngine.getLifecycleChannel().appIsDetached();
      FlutterEngineCache.getInstance().remove(NextSenseApplication.FLUTTER_ENGINE_NAME);
    }
  }

  private void stopService() {
    stopService(foregroundServiceIntent);
  }

  private void startFlutter(Intent intent) {
    if (FlutterEngineCache.getInstance().get(NextSenseApplication.FLUTTER_ENGINE_NAME) == null) {
      ((NextSenseApplication) getApplicationContext()).initFlutterEngineCache();
    }
    startActivity(getFlutterIntent(intent));
  }

  private Intent getFlutterIntent(@Nullable Intent androidIntent) {
    Intent flutterIntent = FlutterActivity.withCachedEngine(
            NextSenseApplication.FLUTTER_ENGINE_NAME).build(this);
    if (androidIntent != null && androidIntent.getExtras() != null) {
      Log.i(TAG, "New intent received extras: " + androidIntent.getExtras().toString());
      String jsonData = androidIntent.getExtras().getString(EXTRA_NOTIFICATION_JSON);
      if (jsonData != null) {
        Log.i(TAG, "New intent received json: " +
            androidIntent.getExtras().get(EXTRA_NOTIFICATION_JSON));
        Map notificationData = gson.fromJson(jsonData, Map.class);
        Map<String, String> payloadMap = (Map<String, String>)
                ((Map) notificationData.get(JSON_KEY_CONTENT)).get(JSON_KEY_PAYLOAD);
        for (Map.Entry<String, String> entry : payloadMap.entrySet()) {
          flutterIntent.putExtra(entry.getKey(), entry.getValue());
        }
      }
    }
    return flutterIntent;
  }

  private final ServiceConnection nextSenseConnection = new ServiceConnection() {

    @Override
    public void onServiceConnected(ComponentName className, IBinder service) {
      // We've bound to LocalService, cast the IBinder and get LocalService instance
      ForegroundService.LocalBinder binder = (ForegroundService.LocalBinder) service;
      nextSenseService = binder.getService();
      nextSenseServiceBound = true;
      Log.i(TAG, "service bound. Flutter active: " +
          nextSenseService.isFlutterActivityActive());
      if (AUTOSTART_FLUTTER) {
        if (nextSenseService.isFlutterActivityActive()) {
          startFlutter(initialIntent);
          initialIntent = null;
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