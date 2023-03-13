package io.nextsense.android.main;

import android.app.Application;
import android.util.Log;

import com.google.firebase.FirebaseApp;
import com.google.firebase.appcheck.FirebaseAppCheck;
import com.google.firebase.appcheck.debug.DebugAppCheckProviderFactory;
import com.google.firebase.appcheck.playintegrity.PlayIntegrityAppCheckProviderFactory;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterEngineCache;
import io.flutter.embedding.engine.dart.DartExecutor;

/**
 * Custom application class for the NextSense application.
 */
public class NextSenseApplication extends Application {

  public static final String FLUTTER_ENGINE_NAME = "nextsense_engine_id";

  private FlutterEngine flutterEngine;

  @Override
  public void onCreate() {
    super.onCreate();
    initFirebase();
    initFlutterEngineCache();
  }

  private void initFirebase() {
    FirebaseApp.initializeApp(getApplicationContext());
    FirebaseAppCheck firebaseAppCheck = FirebaseAppCheck.getInstance();
    if (BuildConfig.DEBUG) {
      firebaseAppCheck.installAppCheckProviderFactory(
          DebugAppCheckProviderFactory.getInstance());
    } else {
      firebaseAppCheck.installAppCheckProviderFactory(
          PlayIntegrityAppCheckProviderFactory.getInstance());
    }
  }

  public void initFlutterEngineCache() {
    Log.i("NextSenseApplication", "Initializing the flutter engine.");
    // Instantiate a FlutterEngine.
    flutterEngine = new FlutterEngine(this);

    // Start executing Dart code to pre-warm the FlutterEngine.
    flutterEngine.getDartExecutor().executeDartEntrypoint(
        DartExecutor.DartEntrypoint.createDefault()
    );

    // Cache the FlutterEngine to be used by FlutterActivity.
    FlutterEngineCache
        .getInstance()
        .put(FLUTTER_ENGINE_NAME, flutterEngine);
  }
}
