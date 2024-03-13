package io.nextsense.android.main.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableStateOf
import androidx.core.app.NotificationCompat
import androidx.lifecycle.LifecycleService
import androidx.lifecycle.lifecycleScope
import androidx.wear.ongoing.OngoingActivity
import androidx.wear.ongoing.Status
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequest
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.workDataOf
import dagger.hilt.android.AndroidEntryPoint
import io.nextsense.android.main.MainActivity
import io.nextsense.android.main.data.DataTypeAvailability
import io.nextsense.android.main.data.LocalDatabaseManager
import io.nextsense.android.main.db.AccelerometerEntity
import io.nextsense.android.main.db.HeartRateEntity
import io.nextsense.android.main.lucid.R
import io.nextsense.android.main.presentation.MILLISECONDS_PER_SECOND
import io.nextsense.android.main.utils.Logger
import io.nextsense.android.main.utils.SleepStagePredictionHelper
import io.nextsense.android.main.utils.minutesToMilliseconds
import io.nextsense.android.main.utils.toFormattedDateString
import io.nextsense.android.main.utils.toSeconds
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.util.concurrent.TimeUnit
import javax.inject.Inject


@AndroidEntryPoint
class HealthService : LifecycleService(), SensorEventListener {

    @Inject
    lateinit var sleepStagePredictionHelper: SleepStagePredictionHelper

    @Inject
    lateinit var localDatabaseManager: LocalDatabaseManager

    @Inject
    lateinit var logger: Logger

    private lateinit var sensorManager: SensorManager
    private var accelerometer: Sensor? = null
    private var heartRateSensor: Sensor? = null
    private val maxReportLatencyUs = 1000000 // 1 second
    private var lastAccelerometerDataSavedTimestamp = 0L
    private var lastHeartRateDataSavedTimestamp = 0L
    private val initialWaitingTime = minutesToMilliseconds(15)
    val availability: MutableState<DataTypeAvailability> =
        mutableStateOf(DataTypeAvailability.UNKNOWN)
    private val binder = HealthServiceBinder()

    val serviceRunningInForeground: Boolean
        get() = this.foregroundServiceType != ServiceInfo.FOREGROUND_SERVICE_TYPE_NONE

    inner class HealthServiceBinder : Binder() {
        fun getService(): HealthService {
            return this@HealthService
        }
    }

    override fun onBind(intent: Intent): IBinder {
        super.onBind(intent)
        return binder
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        super.onStartCommand(intent, flags, startId)
        startForeground(NOTIFICATION_ID, createNotification())
        sensorManager = getSystemService(SENSOR_SERVICE) as SensorManager
        accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        heartRateSensor = sensorManager.getDefaultSensor(Sensor.TYPE_HEART_RATE)
        if (accelerometer != null && heartRateSensor != null) {
            sensorManager.registerListener(
                this, accelerometer, SensorManager.SENSOR_DELAY_NORMAL, maxReportLatencyUs
            )
            sensorManager.registerListener(
                this, heartRateSensor, SensorManager.SENSOR_DELAY_UI, maxReportLatencyUs
            )
            lifecycleScope.launch {
                availability.value = DataTypeAvailability.AVAILABLE
            }
        }
        startPredicationWork(true)
        return START_STICKY
    }

    private fun createNotification(): Notification {
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            notificationIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notificationBuilder = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("HealthService Service")
            .setContentText("Service is running in the background")
            .setSmallIcon(R.drawable.ic_stat_onesignal_default).setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationChannel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "HealthService Service Channel",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            val notificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(notificationChannel)
        }

        val ongoingActivityStatus = Status.Builder().addTemplate(ONGOING_STATUS_TEMPLATE).build()
        val ongoingActivity =
            OngoingActivity.Builder(applicationContext, NOTIFICATION_ID, notificationBuilder)
                .setAnimatedIcon(R.drawable.ic_stat_onesignal_default)
                .setStaticIcon(R.drawable.ic_stat_onesignal_default).setTouchIntent(pendingIntent)
                .setStatus(ongoingActivityStatus).build()

        ongoingActivity.apply(applicationContext)
        return notificationBuilder.build()
    }


    override fun onSensorChanged(event: SensorEvent?) {
        event?.let {
            when (it.sensor) {
                accelerometer -> {
                    // Check if enough time has passed since the last saved data or it's the first data
                    if (shouldSaveAccelerometerData()) {
                        val timestamp = System.currentTimeMillis()
                        val x = (it.values?.getOrNull(0) ?: 0).toDouble()
                        val y = (it.values?.getOrNull(1) ?: 0).toDouble()
                        val z = (it.values?.getOrNull(2) ?: 0f).toDouble()
                        saveAccelerometerData(timestamp, x, y, z)
                        // Update the last saved timestamp
                        lastAccelerometerDataSavedTimestamp = timestamp
                        logger.log("Accelerometer=>X:${x}, y:${y}, z:${z}")
                    }
                }

                heartRateSensor -> {
                    val mHeartRateFloat = event.values[0].toDouble()
                    if (shouldSaveHeartRateData()) {
                        saveHeartRateData(mHeartRateFloat)
                        lastHeartRateDataSavedTimestamp = System.currentTimeMillis()
                        logger.log("Heart Rate=>${mHeartRateFloat}")
                    }
                }

                else -> {}
            }
        }
    }

    override fun onAccuracyChanged(p0: Sensor?, p1: Int) {
    }

    private fun saveAccelerometerData(timestamp: Long, x: Double, y: Double, z: Double) {
        lifecycleScope.launch(Dispatchers.IO) {
            try {
                val accelerometerEntity = AccelerometerEntity(
                    x = x,
                    y = y,
                    z = z,
                    createAt = timestamp.toSeconds(),
                    date = timestamp.toFormattedDateString()
                )
                localDatabaseManager.accelerometerDao?.insertAll(accelerometerEntity)
            } catch (e: Exception) {
                logger.log("${e.message}")
            }
        }
    }

    private fun shouldSaveAccelerometerData(): Boolean {
        val elapsedTime: Long = System.currentTimeMillis() - lastAccelerometerDataSavedTimestamp
        return elapsedTime >= MILLISECONDS_PER_SECOND || lastAccelerometerDataSavedTimestamp == 0L
    }

    private fun shouldSaveHeartRateData(): Boolean {
        val elapsedTime: Long = System.currentTimeMillis() - lastHeartRateDataSavedTimestamp
        return elapsedTime >= MILLISECONDS_PER_SECOND || lastHeartRateDataSavedTimestamp == 0L
    }

    private fun saveHeartRateData(heartRate: Double) {
        lifecycleScope.launch(Dispatchers.IO) {
            try {
                val timestamp = System.currentTimeMillis()
                val heartRateEntity = HeartRateEntity(
                    heartRate = heartRate,
                    createAt = timestamp.toSeconds(),
                    date = timestamp.toFormattedDateString()
                )
                localDatabaseManager.heartRateDao?.insertAll(heartRateEntity)
            } catch (e: Exception) {
                logger.log("${e.message}")
            }
        }
    }

    private fun startPredicationWork(isServiceRunning: Boolean) {
        val uploadRequest: OneTimeWorkRequest =
            OneTimeWorkRequestBuilder<PredictionWork>().setInputData(
                workDataOf(
                    Pair(
                        IS_SERVICE_RUNNING, isServiceRunning
                    )
                )
            ).setInitialDelay(
                if (isServiceRunning) initialWaitingTime.toLong() else 0L, TimeUnit.MILLISECONDS
            ).build()
        WorkManager.getInstance(this)
            .enqueueUniqueWork(REM_PREDICTION_WORK, ExistingWorkPolicy.REPLACE, uploadRequest)
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            sensorManager.unregisterListener(this)
            removeOngoingActivityNotification()
            startPredicationWork(false)
        } catch (e: Exception) {
            logger.log("${e.message}")
        }
    }

    private fun removeOngoingActivityNotification() {
        if (serviceRunningInForeground) {
            Log.d(ContentValues.TAG, "Removing ongoing activity notification")
            stopForeground(STOP_FOREGROUND_REMOVE)
        }
    }

    companion object {
        private const val NOTIFICATION_CHANNEL_ID = "HealthServiceChannel"
        private const val NOTIFICATION_ID = 101
        private const val ONGOING_STATUS_TEMPLATE = "Ongoing REM checking"
    }

}