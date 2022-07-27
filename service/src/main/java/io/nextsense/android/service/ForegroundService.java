package io.nextsense.android.service;

import android.app.Activity;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.os.Binder;
import android.os.Build;
import android.os.IBinder;
import android.util.Log;

import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;

import java.time.Duration;
import java.util.Arrays;

import io.nextsense.android.Config;
import io.nextsense.android.base.DeviceManager;
import io.nextsense.android.base.DeviceScanner;
import io.nextsense.android.base.SampleRateCalculator;
import io.nextsense.android.base.communication.ble.BleCentralManagerProxy;
import io.nextsense.android.base.communication.internet.Connectivity;
import io.nextsense.android.base.data.LocalSessionManager;
import io.nextsense.android.base.data.Uploader;
import io.nextsense.android.base.db.CacheSink;
import io.nextsense.android.base.db.DatabaseSink;
import io.nextsense.android.base.db.memory.MemoryCache;
import io.nextsense.android.base.db.objectbox.ObjectBoxDatabase;
import io.nextsense.android.base.devices.NextSenseDeviceManager;
import io.nextsense.android.base.utils.Util;

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

  private static final String TAG = ForegroundService.class.getSimpleName();
  private static final String CHANNEL_ID = "NextSenseChannel";
  private static final String CHANNEL_NAME = "NextSense";
  private static final int UI_INTENT_REQUEST_CODE = 1;
  private static final int NOTIFICATION_ID = 1;

  // Binder given to clients.
  private final IBinder binder = new LocalBinder();

  private BleCentralManagerProxy centralManagerProxy;
  private DeviceScanner deviceScanner;
  private DeviceManager deviceManager;
  private ObjectBoxDatabase objectBoxDatabase;
  private MemoryCache memoryCache;
  private DatabaseSink databaseSink;
  private CacheSink cacheSink;
  private LocalSessionManager localSessionManager;
  private Connectivity connectivity;
  private Uploader uploader;
  private SampleRateCalculator sampleRateCalculator;
  private boolean initialized = false;
  // Starts true so the activity is launched on first start.
  private boolean flutterActivityActive = true;

  @Override
  @SuppressWarnings("unchecked")
  public int onStartCommand(Intent intent, int flags, int startId) {
    Util.logd(TAG, "onStartCommand start.");
    if (initialized) {
      Log.i(TAG, "Already initialized, keep running.");
      return START_REDELIVER_INTENT;
    }
    createNotificationChannel();
    if (intent == null || intent.getExtras() == null) {
      return START_REDELIVER_INTENT;
    }
    Class<Activity> uiClass = (Class<Activity>) intent.getSerializableExtra(EXTRA_UI_CLASS);
    Intent notificationIntent = new Intent(this, uiClass);
    PendingIntent pendingIntent = PendingIntent.getActivity(this,
        UI_INTENT_REQUEST_CODE, notificationIntent, PendingIntent.FLAG_IMMUTABLE);
    Notification notification = new NotificationCompat.Builder(this, CHANNEL_ID)
        .setContentTitle(getString(R.string.app_name))
        .setContentText(getString(R.string.notif_content))
        .setSmallIcon(R.drawable.ic_launcher)
        .setContentIntent(pendingIntent)
        .build();
    startForeground(NOTIFICATION_ID, notification);
    initialize();
    Util.logd(TAG, "Service initialized.");
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

  private void initialize() {
    objectBoxDatabase = new ObjectBoxDatabase();
    objectBoxDatabase.init(this);
    localSessionManager = LocalSessionManager.create(objectBoxDatabase);
    centralManagerProxy = (!Config.USE_EMULATED_BLE) ?
            new BleCentralManagerProxy(getApplicationContext()) : null;
    deviceScanner = DeviceScanner.create(NextSenseDeviceManager.create(localSessionManager),
        centralManagerProxy);
    deviceManager = DeviceManager.create(deviceScanner, localSessionManager);
    databaseSink = DatabaseSink.create(objectBoxDatabase);
    databaseSink.startListening();
    // sampleRateCalculator = SampleRateCalculator.create(250);
    // sampleRateCalculator.startListening();
    memoryCache = MemoryCache.create(
            Arrays.asList("1", "3", "6", "7", "8"), Arrays.asList("x", "y", "z"));
    cacheSink = CacheSink.create(memoryCache);
    cacheSink.startListening();
    connectivity = Connectivity.create(this);
    // uploadChunkSize should be by chunks of 1 second of data to match BigTable transaction size.
    // minRecordsToKeep is set at 5000 as ~4000 records is the upper limit we are considering for
    // impedance calculation.
    uploader = Uploader.create(objectBoxDatabase, connectivity, /*uploadChunk=*/1250,
        /*minRecordsToKeep=*/5000, /*minDurationToKeep=*/Duration.ofMillis((5000 / 250) * 1000L));
    uploader.start();
    initialized = true;
  }

  private void destroy() {
    Log.i(TAG, "destroy started.");
    // sampleRateCalculator.stopListening();
    if (deviceScanner != null) {
      deviceScanner.close();
    }
    if (deviceManager != null) {
      deviceManager.close();
    }
    if (centralManagerProxy != null) {
      centralManagerProxy.close();
    }
    cacheSink.stopListening();
    memoryCache = null;
    databaseSink.stopListening();
    if (uploader != null) {
      uploader.stop();
    }
    objectBoxDatabase.stop();
    initialized = false;
    Log.i(TAG, "destroy finished.");
  }

  private void createNotificationChannel() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      NotificationChannel serviceChannel = new NotificationChannel(
          CHANNEL_ID,
          CHANNEL_NAME,
          NotificationManager.IMPORTANCE_DEFAULT
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