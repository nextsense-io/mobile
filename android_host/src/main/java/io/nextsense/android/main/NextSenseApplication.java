package io.nextsense.android.main;

import android.app.Application;

import com.google.firebase.FirebaseApp;
import com.google.firebase.appcheck.FirebaseAppCheck;
import com.google.firebase.appcheck.debug.DebugAppCheckProviderFactory;
import com.google.firebase.appcheck.playintegrity.PlayIntegrityAppCheckProviderFactory;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterEngineCache;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.nextsense.android.ApplicationType;
import io.nextsense.android.ApplicationTypeHelper;
import io.nextsense.android.base.utils.RotatingFileLogger;

/**
 * Custom application class for the NextSense application.
 */
public class NextSenseApplication extends Application {

  public static final String FLUTTER_ENGINE_NAME = "nextsense_engine_id";
  private static final String TAG = NextSenseApplication.class.getSimpleName();
  private static final String ROUTE_CONSUMER_UI = "/consumer_ui";
  private static final String ROUTE_TRIAL_UI = "/trial_ui";
  private static final String LUCID_UI = "/lucid_ui";


  private ApplicationType applicationType;
  private FlutterEngine flutterEngine;

  @Override
  public void onCreate() {
    super.onCreate();
    RotatingFileLogger.initialize(getApplicationContext());
    initApplicationType();
    initFirebase();
    initFlutterEngineCache();
  }

  private void initApplicationType() {
    applicationType = ApplicationTypeHelper.getApplicationType(BuildConfig.FLAVOR);
    RotatingFileLogger.get().logi(TAG, "Application type: " + applicationType);
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
    RotatingFileLogger.get().logi(TAG, "Initializing the flutter engine.");
    // Instantiate a FlutterEngine.
    flutterEngine = new FlutterEngine(this);

    // Initial route which determines which Flutter module will be used.
    String route = ROUTE_TRIAL_UI;
    if (applicationType == ApplicationType.CONSUMER) {
      route = ROUTE_CONSUMER_UI;
    } else if (applicationType == ApplicationType.LUCID_REALITY) {
      route = LUCID_UI;
    }
    flutterEngine.getNavigationChannel().setInitialRoute(route);

    // Start executing Dart code to pre-warm the FlutterEngine.
    flutterEngine.getDartExecutor().executeDartEntrypoint(
        DartExecutor.DartEntrypoint.createDefault()
    );

    // Cache the FlutterEngine to be used by FlutterActivity.
    FlutterEngineCache
        .getInstance()
        .put(FLUTTER_ENGINE_NAME, flutterEngine);
  }

  public ApplicationType getApplicationType() {
    return applicationType;
  }
}
