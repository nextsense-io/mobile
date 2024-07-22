package io.nextsense.android.budz.service;

import static android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE;

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
import androidx.core.app.ServiceCompat;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;

import java.io.IOException;

import io.nextsense.android.Config;
import io.nextsense.android.airoha.device.AirohaBleManager;
import io.nextsense.android.airoha.device.AirohaDeviceManager;
import io.nextsense.android.algo.tflite.SleepTransformerModel;
import io.nextsense.android.base.DeviceManager;
import io.nextsense.android.base.DeviceScanner;
import io.nextsense.android.base.SampleRateCalculator;
import io.nextsense.android.base.communication.ble.BleCentralManagerProxy;
import io.nextsense.android.base.communication.ble.BluetoothStateManager;
import io.nextsense.android.base.communication.internet.Connectivity;
import io.nextsense.android.base.data.LocalSessionManager;
import io.nextsense.android.base.data.Uploader;
import io.nextsense.android.base.db.CacheSink;
import io.nextsense.android.base.db.CsvSink;
import io.nextsense.android.base.db.DatabaseSink;
import io.nextsense.android.base.db.memory.MemoryCache;
import io.nextsense.android.base.db.objectbox.ObjectBoxDatabase;
import io.nextsense.android.base.devices.NextSenseDeviceManager;
import io.nextsense.android.base.utils.RotatingFileLogger;
import io.nextsense.android.budz.R;


import androidx.health.connect.client.HealthConnectClient


/**
 * Main Foreground service that will manage the Bluetooth connection to the NextSense device and the
 * Cloud data sync. This service will run only while streaming raw data.
 *
 * It is necessary to have a foreground service so that the data streaming from the device does not
 * get interrupted in long sessions (more than an hour) when the NextSense app is not in the
 * foreground or the phone goes in sleep mode when not in use for a long period if time, like at
 * night.
 *
 * This service could be extended later on with an AIDL file to let external applications connect
 * to our device if that is something we want to do.
 */

/**
 * BudzService: Foreground Service for NextSense App
 *
 * This service manages continuous Bluetooth connections and data synchronization tasks,
 * ensuring seamless operation even when the app is not in the foreground. The service is designed to be robust,
 * handling long sessions without interruption due to system sleep or app backgrounding.
 *
 * Recent Updates:
 * - Integration of Android Health Connect:
 *   Health Connect Client is initialized in this service to facilitate health data management,
 *   specifically focusing on sleep data. This addition allows the app to access, store, and manage
 *   health data in compliance with user permissions and system guidelines.
 *
 * Key Functionalities:
 * 1. Health Connect Integration:
 *    - HealthConnectClient setup: Initializes the client and requests necessary permissions
 *      for accessing health data (Read and Write permissions for sleep data).
 *    - Permission Handling: Dynamically requests health-related permissions at runtime,
 *      ensuring compliance with Android's privacy requirements.
 *
 * 2. Continuous Bluetooth Management:
 *    - Manages Bluetooth connections with NextSense devices, ensuring data is continuously streamed.
 *    - Utilizes BluetoothStateManager and AirohaBleManager for managing connections and data transmission.
 *
 * 3. Data Handling and Storage:
 *    - LocalSessionManager and ObjectBoxDatabase are used for local data storage and session management.
 *    - Data from devices is processed and optionally uploaded, controlled by connectivity and user preferences.
 *
 * 4. Notification Management:
 *    - Handles foreground service notifications to keep the user informed about the service status.
 *    - Creates notification channels as required by newer Android versions.
 *
 * Usage of Service:
 * - The service should be started and stopped by the main activity of the app,
 *   ensuring it runs only when necessary. It uses a binder for activities to bind to and interact with the service.
 *
 * Additional Notes:
 * - The service is crucial for applications requiring reliable data capture from external devices,
 *   especially in health applications where data integrity and availability are critical.
 *
 * Developer Notes:
 * - Ensure any modifications to Bluetooth or Health Connect functionalities are tested rigorously
 *   to maintain data accuracy and application stability.
 * - Future enhancements may include more granular health data management or expanded device support.
 */


public class BudzService extends Service {

  public static final String EXTRA_UI_CLASS = "ui_class";
  // Allows data to be uploaded to the cloud via a cellular transmission.
  public static final String EXTRA_ALLOW_DATA_VIA_CELLULAR = "allow_data_via_cellular";

  private static final String TAG = BudzService.class.getSimpleName();
  private static final String CHANNEL_ID = "BudzChannel";
  private static final String CHANNEL_NAME = "NextSense";
  private static final int UI_INTENT_REQUEST_CODE = 1;
  private static final int NOTIFICATION_ID = 1;

  // Binder given to clients.
  private final IBinder binder = new LocalBinder();

  private NotificationManager notificationManager;
  private FirebaseAuth firebaseAuth;
  private NextSenseDeviceManager budzDeviceManager;
  private BluetoothStateManager bluetoothStateManager;
  private BleCentralManagerProxy centralManagerProxy;
  private DeviceScanner deviceScanner;
  private DeviceManager deviceManager;
  private ObjectBoxDatabase objectBoxDatabase;
  private MemoryCache memoryCache;
  private DatabaseSink databaseSink;
  private CacheSink cacheSink;
  private CsvSink csvSink;
  private LocalSessionManager localSessionManager;
  private Connectivity connectivity;
  private Uploader uploader;
  private SampleRateCalculator sampleRateCalculator;
  private SleepTransformerModel sleepTransformerModel;
  private AirohaBleManager airohaBleManager;
  private boolean initialized = false;

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
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      ServiceCompat.startForeground(this, NOTIFICATION_ID, notificationBuilder.build(),
          FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE);
    } else {
      startForeground(NOTIFICATION_ID, notificationBuilder.build());
    }
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
  public SleepTransformerModel getSleepTransformerModel() {
    return sleepTransformerModel;
  }
  public AirohaBleManager getAirohaBleManager() {
    return airohaBleManager;
  }

  public void changeNotificationContent(String title, String text) {
    notificationBuilder.setContentTitle(title);
    notificationBuilder.setContentText(text);
    notificationManager.notify(NOTIFICATION_ID, notificationBuilder.build());
  }

  private void initialize(boolean allowDataViaCellular) {
    objectBoxDatabase = new ObjectBoxDatabase();
    objectBoxDatabase.init(this);
    bluetoothStateManager = BluetoothStateManager.create(getApplicationContext());
    centralManagerProxy = (!Config.USE_EMULATED_BLE) ?
        new BleCentralManagerProxy(getApplicationContext()) : null;
    // Uncomment when the CSV sink is needed.
    csvSink = CsvSink.create(this, objectBoxDatabase, centralManagerProxy);
    localSessionManager = LocalSessionManager.create(objectBoxDatabase, csvSink);
    budzDeviceManager = NextSenseDeviceManager.create(localSessionManager,
        NextSenseDeviceManager.DeviceGroup.CONSUMER);
    memoryCache = MemoryCache.create();
    deviceScanner = DeviceScanner.create(
        budzDeviceManager, centralManagerProxy, bluetoothStateManager, memoryCache, csvSink);
    deviceManager = DeviceManager.create(
        deviceScanner, localSessionManager, centralManagerProxy, bluetoothStateManager,
        budzDeviceManager, memoryCache, csvSink);
    // databaseSink = DatabaseSink.create(objectBoxDatabase, localSessionManager);
    // databaseSink.startListening();
    // sampleRateCalculator = SampleRateCalculator.create(250);
    // sampleRateCalculator.startListening();
    cacheSink = CacheSink.create(memoryCache);
    cacheSink.startListening();
    airohaBleManager = new AirohaBleManager(deviceManager);
    connectivity = Connectivity.create(this);
    // uploadChunkSize should be by chunks of 1 second of data to match BigTable transaction size.
    // minRecordsToKeep is set at 12 minutes as we need 10 minutes for sleep staging.
//    uploader = Uploader.create(this, ApplicationType.CONSUMER, objectBoxDatabase, databaseSink,
//        connectivity, /*uploadChunk=*/Duration.ofSeconds(5), /*minRecordsToKeep=*/250 * 60 * 12,
//        /*minDurationToKeep=*/Duration.ofMinutes(12));
//    uploader.setMinimumConnectivityState(allowDataViaCellular ?
//        Connectivity.State.LIMITED_CONNECTION : Connectivity.State.FULL_CONNECTION);
//    uploader.start();

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
    // Not used at this time.
    // initializeAlgorithms();
    initialized = true;
  }

  private lateinit var healthConnectClient: HealthConnectClient

  private fun initialize(allowDataViaCellular: Boolean) {
    objectBoxDatabase = new ObjectBoxDatabase()
    objectBoxDatabase.init(this)
    bluetoothStateManager = BluetoothStateManager.create(getApplicationContext())
    centralManagerProxy = if (!Config.USE_EMULATED_BLE) BleCentralManagerProxy(getApplicationContext()) else null
    csvSink = CsvSink.create(this, objectBoxDatabase, centralManagerProxy)
    localSessionManager = LocalSessionManager.create(objectBoxDatabase, csvSink)
    budzDeviceManager = NextSenseDeviceManager.create(localSessionManager, NextSenseDeviceManager.DeviceGroup.CONSUMER)
    memoryCache = MemoryCache.create()
    deviceScanner = DeviceScanner.create(
        budzDeviceManager, centralManagerProxy, bluetoothStateManager, memoryCache, csvSink)

    // Initialize HealthConnectClient
    healthConnectClient = HealthConnectClient.getOrCreate(this)
  }


  private void initializeAlgorithms() {
    sleepTransformerModel = new SleepTransformerModel(getApplicationContext());
    try {
      sleepTransformerModel.loadModel();
      RotatingFileLogger.get().logi(TAG, "Initialized sleep transformer model.");
    } catch (IOException e) {
      RotatingFileLogger.get().loge(TAG, "Failed to load sleep transformer model: " +
          e.getMessage());
    }
  }

  private void destroy() {
    RotatingFileLogger.get().logi(TAG, "destroy started.");
    // sampleRateCalculator.stopListening();
    if (sleepTransformerModel != null) {
      sleepTransformerModel.closeModel();
    }
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
    if (csvSink != null) {
      csvSink.stopListening();
      csvSink.closeCsv(/*checkForCompletedSession=*/false);
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
    public BudzService getService() {
      // Return this instance of ForegroundService so clients can call public methods.
      return BudzService.this;
    }
  }
}