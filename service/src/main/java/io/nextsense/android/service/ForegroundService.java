package io.nextsense.android.service;

import android.app.Activity;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.Binder;
import android.os.Build;
import android.os.IBinder;

import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;

import java.time.Duration;
import java.util.Arrays;

import io.nextsense.android.Config;
import io.nextsense.android.base.DeviceManager;
import io.nextsense.android.base.DeviceScanner;
import io.nextsense.android.base.SampleRateCalculator;
import io.nextsense.android.base.communication.ble.BleCentralManagerProxy;
import io.nextsense.android.base.communication.ble.BluetoothStateManager;
import io.nextsense.android.base.communication.firebase.CloudFunctions;
import io.nextsense.android.base.communication.internet.Connectivity;
import io.nextsense.android.base.data.LocalSessionManager;
import io.nextsense.android.base.data.Uploader;
import io.nextsense.android.base.db.CacheSink;
import io.nextsense.android.base.db.DatabaseSink;
import io.nextsense.android.base.db.memory.MemoryCache;
import io.nextsense.android.base.db.objectbox.ObjectBoxDatabase;
import io.nextsense.android.base.devices.NextSenseDeviceManager;
import io.nextsense.android.base.utils.RotatingFileLogger;

/**
 * Main Foreground service that will manage the Bluetooth connection to the NextSense device and the
 * Cloud data sync.
 *
 * It is necessary to have a foreground service so that the data streaming from the device does not
 * get interrupted in long sessions (more than an hour) when the NextSense app is not in the
 * foreground or the phone goes in sleep mode when not in use for a long period if time, like at
 * night.
 *
 * This service could be extended later on with an AIDL file to let external applications connect
 * to our device if that is something we want to do.
 */
public class ForegroundService extends Service {
  // Class reference to know what to launch when the service notification is pressed.
  public static final String EXTRA_UI_CLASS = "ui_class";
  // Allows data to be uploaded to the cloud via a cellular transmission.
  public static final String EXTRA_ALLOW_DATA_VIA_CELLULAR = "allow_data_via_cellular";

  private static final String TAG = ForegroundService.class.getSimpleName();
  private static final String CHANNEL_ID = "NextSenseChannel";
  private static final String CHANNEL_NAME = "NextSense";
  private static final int UI_INTENT_REQUEST_CODE = 1;
  private static final int NOTIFICATION_ID = 1;

  // Binder given to clients.
  private final IBinder binder = new LocalBinder();

  private NotificationManager notificationManager;
  private FirebaseAuth firebaseAuth;
  private NextSenseDeviceManager nextSenseDeviceManager;
  private BluetoothStateManager bluetoothStateManager;
  private BleCentralManagerProxy centralManagerProxy;
  private DeviceScanner deviceScanner;
  private DeviceManager deviceManager;
  private ObjectBoxDatabase objectBoxDatabase;
  private MemoryCache memoryCache;
  private DatabaseSink databaseSink;
  private CacheSink cacheSink;
  private LocalSessionManager localSessionManager;
  private Connectivity connectivity;
  private CloudFunctions cloudFunctions;
  private Uploader uploader;
  private SampleRateCalculator sampleRateCalculator;
  private boolean initialized = false;
  // Starts true so the activity is launched on first start.
  private boolean flutterActivityActive = true;

  private NotificationCompat.Builder notificationBuilder;

  @Override
  @SuppressWarnings("unchecked")
  public int onStartCommand(Intent intent, int flags, int startId) {
    RotatingFileLogger.get().logd(TAG, "onStartCommand start.");
    if (initialized) {
      RotatingFileLogger.get().logi(TAG, "Already initialized, keep running.");
      return START_REDELIVER_INTENT;
    }
    notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
    createNotificationChannel();
    if (intent == null || intent.getExtras() == null) {
      return START_REDELIVER_INTENT;
    }

    Class<Activity> uiClass = (Class<Activity>) intent.getSerializableExtra(EXTRA_UI_CLASS);
    Intent notificationIntent = new Intent(this, uiClass);
    PendingIntent pendingIntent = PendingIntent.getActivity(this,
        UI_INTENT_REQUEST_CODE, notificationIntent, PendingIntent.FLAG_IMMUTABLE);
    notificationBuilder = new NotificationCompat.Builder(this, CHANNEL_ID)
        .setContentTitle(getString(R.string.app_name))
        .setContentText(getString(R.string.notif_content))
        .setSmallIcon(R.drawable.ic_stat_nextsense_n_icon)
        .setContentIntent(pendingIntent);
    startForeground(NOTIFICATION_ID, notificationBuilder.build());
    initialize(intent.getBooleanExtra(EXTRA_ALLOW_DATA_VIA_CELLULAR, false));
    RotatingFileLogger.get().logd(TAG, "Service initialized.");
    return START_REDELIVER_INTENT;
  }

  @Override
  public void onDestroy() {
    destroy();
    super.onDestroy();
  }

  @Nullable
  @Override
  public IBinder onBind(Intent intent) {
    return binder;
  }

  public DeviceManager getDeviceManager() {
    return deviceManager;
  }

  public ObjectBoxDatabase getObjectBoxDatabase() {
    return objectBoxDatabase;
  }

  public MemoryCache getMemoryCache() {
    return memoryCache;
  }

  public LocalSessionManager getLocalSessionManager() {
    return localSessionManager;
  }

  public SampleRateCalculator getSampleRateCalculator() {
    return sampleRateCalculator;
  }

  public Uploader getUploader() {
    return uploader;
  }

  public boolean isFlutterActivityActive() {
    return flutterActivityActive;
  }

  public void setFlutterActivityActive(boolean active) {
    flutterActivityActive = active;
  }

  public void changeNotificationContent(String title, String text) {
    notificationBuilder.setContentTitle(title);
    notificationBuilder.setContentText(text);
    notificationManager.notify(NOTIFICATION_ID, notificationBuilder.build());
  }

  private void initialize(boolean allowDataViaCellular) {
    objectBoxDatabase = new ObjectBoxDatabase();
    objectBoxDatabase.init(this);
    localSessionManager = LocalSessionManager.create(objectBoxDatabase);
    bluetoothStateManager = BluetoothStateManager.create(getApplicationContext());
    centralManagerProxy = (!Config.USE_EMULATED_BLE) ?
            new BleCentralManagerProxy(getApplicationContext()) : null;
    nextSenseDeviceManager = NextSenseDeviceManager.create(localSessionManager);
    memoryCache = MemoryCache.create();
    deviceScanner = DeviceScanner.create(
        nextSenseDeviceManager, centralManagerProxy, bluetoothStateManager, memoryCache);
    deviceManager = DeviceManager.create(
        deviceScanner, localSessionManager, centralManagerProxy, bluetoothStateManager,
        nextSenseDeviceManager, memoryCache);
    databaseSink = DatabaseSink.create(objectBoxDatabase, localSessionManager);
    databaseSink.startListening();
    // sampleRateCalculator = SampleRateCalculator.create(250);
    // sampleRateCalculator.startListening();
    cacheSink = CacheSink.create(memoryCache);
    cacheSink.startListening();
    connectivity = Connectivity.create(this);
    // uploadChunkSize should be by chunks of 1 second of data to match BigTable transaction size.
    // minRecordsToKeep is set at 5000 as ~4000 records is the upper limit we are considering for
    // impedance calculation.
    uploader = Uploader.create(objectBoxDatabase, databaseSink, connectivity, /*uploadChunk=*/1250,
        /*minRecordsToKeep=*/5000, /*minDurationToKeep=*/Duration.ofMillis((5000 / 250) * 1000L));
    uploader.setMinimumConnectivityState(allowDataViaCellular ?
        Connectivity.State.LIMITED_CONNECTION : Connectivity.State.FULL_CONNECTION);
    uploader.start();
    cloudFunctions = CloudFunctions.create();

    firebaseAuth = FirebaseAuth.getInstance();
    firebaseAuth.addAuthStateListener(firebaseAuth -> {
      FirebaseUser user = firebaseAuth.getCurrentUser();
      if (user != null) {
        // User is signed in
        user.getIdToken(true)
            .addOnSuccessListener(getTokenResult -> {
              // Token refresh succeeded
              // Get new ID token
              String idToken = getTokenResult.getToken();
              RotatingFileLogger.get().logi(TAG, "Refreshed Firebase auth token.");
            })
            .addOnFailureListener(e ->
              // Token refresh failed
              RotatingFileLogger.get().logw(TAG, "Failed to refresh Firebase auth token: " + e.getMessage())
            );
      }
    });

    initialized = true;
  }

  private void destroy() {
    RotatingFileLogger.get().logi(TAG, "destroy started.");
    // sampleRateCalculator.stopListening();
    if (deviceScanner != null) {
      deviceScanner.stopFinding();
      deviceScanner.close();
    }
    if (deviceManager != null) {
      deviceManager.close();
    }
    if (centralManagerProxy != null) {
      centralManagerProxy.close();
    }
    if (cacheSink != null) {
      cacheSink.stopListening();
    }
    memoryCache = null;
    if (databaseSink != null) {
      databaseSink.stopListening();
    }
    if (uploader != null) {
      uploader.stop();
    }
    if (objectBoxDatabase != null) {
      objectBoxDatabase.stop();
    }
    initialized = false;
    RotatingFileLogger.get().logi(TAG, "destroy finished.");
  }

  private void createNotificationChannel() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      NotificationChannel serviceChannel = new NotificationChannel(
          CHANNEL_ID,
          CHANNEL_NAME,
          NotificationManager.IMPORTANCE_LOW
      );
      NotificationManager manager = getSystemService(NotificationManager.class);
      manager.createNotificationChannel(serviceChannel);
    }
  }

  public class LocalBinder extends Binder {
    public ForegroundService getService() {
      // Return this instance of ForegroundService so clients can call public methods.
      return ForegroundService.this;
    }
  }
}