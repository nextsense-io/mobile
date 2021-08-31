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

import io.nextsense.android.base.DeviceManager;
import io.nextsense.android.base.DeviceScanner;
import io.nextsense.android.base.SampleRateCalculator;
import io.nextsense.android.base.communication.ble.BleCentralManagerProxy;
import io.nextsense.android.base.data.LocalSessionManager;
import io.nextsense.android.base.data.Uploader;
import io.nextsense.android.base.db.DatabaseSink;
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
  private static final String TAG = ForegroundService.class.getSimpleName();
  private static final String CHANNEL_ID = "NextSenseChannel";
  private static final String CHANNEL_NAME = "NextSense";
  private static final int UI_INTENT_REQUEST_CODE = 0;
  private static final int NOTIFICATION_ID = 1;

  // Binder given to clients.
  private final IBinder binder = new LocalBinder();

  private BleCentralManagerProxy centralManagerProxy;
  private DeviceScanner deviceScanner;
  private DeviceManager deviceManager;
  private ObjectBoxDatabase objectBoxDatabase;
  private DatabaseSink databaseSink;
  private LocalSessionManager localSessionManager;
  private Uploader uploader;
  private SampleRateCalculator sampleRateCalculator;
  private boolean initialized = false;

  @Override
  @SuppressWarnings("unchecked")
  public int onStartCommand(Intent intent, int flags, int startId) {
    Util.logd(TAG, "onStartCommand start.");
    if (initialized) {
      Log.i(TAG, "Already initialized, keep running.");
      return START_STICKY;
    }
    createNotificationChannel();
    Class<Activity> uiClass = (Class<Activity>) intent.getSerializableExtra("ui_class");
    Intent notificationIntent = new Intent(this, uiClass);
    PendingIntent pendingIntent = PendingIntent.getActivity(this,
        UI_INTENT_REQUEST_CODE, notificationIntent, PendingIntent.FLAG_IMMUTABLE);
    Notification notification = new NotificationCompat.Builder(this, CHANNEL_ID)
        .setContentTitle("Foreground Service")
        .setContentText("Press to control the device")
        .setSmallIcon(R.drawable.ic_launcher)
        .setContentIntent(pendingIntent)
        .build();
    startForeground(NOTIFICATION_ID, notification);
    initialize();
    Util.logd(TAG, "Service initialized.");
    return START_NOT_STICKY;
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

  public SampleRateCalculator getSampleRateCalculator() {
    return sampleRateCalculator;
  }

  private void initialize() {
    objectBoxDatabase = new ObjectBoxDatabase();
    objectBoxDatabase.init(this);
    localSessionManager = LocalSessionManager.create(objectBoxDatabase);
    centralManagerProxy = new BleCentralManagerProxy(getApplicationContext());
    deviceScanner = new DeviceScanner(NextSenseDeviceManager.create(localSessionManager),
        centralManagerProxy);
    deviceManager = new DeviceManager(deviceScanner);
    databaseSink = DatabaseSink.create(objectBoxDatabase);
    databaseSink.startListening();
    sampleRateCalculator = SampleRateCalculator.create(500);
    sampleRateCalculator.startListening();
    // uploadChunkSize should be by chunks of 1 second of data to match BigTable transaction size.
    uploader = Uploader.create(objectBoxDatabase, /*uploadChunk=*/500);
    uploader.start();
    initialized = true;
  }

  private void destroy() {
    Log.i(TAG, "destroy started.");
    sampleRateCalculator.stopListening();
    if (deviceScanner != null) {
      deviceScanner.close();
    }
    if (deviceManager != null) {
      deviceManager.close();
    }
    if (centralManagerProxy != null) {
      centralManagerProxy.close();
    }
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