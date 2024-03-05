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
import androidx.core.app.NotificationCompat
import androidx.lifecycle.LifecycleService
import androidx.lifecycle.lifecycleScope
import androidx.wear.ongoing.OngoingActivity
import androidx.wear.ongoing.Status
import dagger.hilt.android.AndroidEntryPoint
import io.nextsense.android.main.MainActivity
import io.nextsense.android.main.TAG
import io.nextsense.android.main.data.HealthServicesRepository
import io.nextsense.android.main.data.LocalDatabaseManager
import io.nextsense.android.main.data.MeasureMessage
import io.nextsense.android.main.db.AccelerometerEntity
import io.nextsense.android.main.db.HeartRateEntity
import io.nextsense.android.main.db.PredictionEntity
import io.nextsense.android.main.lucid.dev.R
import io.nextsense.android.main.presentation.MILLISECONDS_PER_SECOND
import io.nextsense.android.main.utils.SleepStagePredictionHelper
import io.nextsense.android.main.utils.SleepStagePredictionOutput
import io.nextsense.android.main.utils.minutesToMilliseconds
import io.nextsense.android.main.utils.toFormattedDateString
import io.nextsense.android.main.utils.toSeconds
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.takeWhile
import kotlinx.coroutines.launch
import java.time.Duration
import java.util.concurrent.TimeUnit
import javax.inject.Inject

@AndroidEntryPoint
class HealthService : LifecycleService(), SensorEventListener {

    @Inject
    lateinit var healthServicesRepository: HealthServicesRepository

    @Inject
    lateinit var sleepStagePredictionHelper: SleepStagePredictionHelper

    @Inject
    lateinit var localDatabaseManager: LocalDatabaseManager
    private lateinit var sensorManager: SensorManager
    private var accelerometer: Sensor? = null
    private var lastSavedTimestamp = 0L
    private val dataCheckingPeriod: Long = MILLISECONDS_PER_SECOND * 30.toLong()
    private val initialWaitingTime = minutesToMilliseconds(15)
    private var schedulerStartTime = 0L
    private var initialWaitingTimeCompleted = false
    private val _heartRateFlow = MutableSharedFlow<MeasureMessage>()
    val heartRateFlow: SharedFlow<MeasureMessage> = _heartRateFlow
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
        if (accelerometer != null) {
            sensorManager.registerListener(this, accelerometer, SensorManager.SENSOR_DELAY_NORMAL)
        }
        lifecycleScope.launch(Dispatchers.IO) {
            val supported = healthServicesRepository.hasHeartRateCapability()
            healthServicesRepository.heartRateMeasureFlow().takeWhile { supported }
                .collect { measureMessage ->
                    _heartRateFlow.emit(measureMessage)
                    when (measureMessage) {
                        is MeasureMessage.MeasureData -> {
                            val hr = measureMessage.data.last().value
                            saveHeartRateData(hr)
                            Log.i(TAG, "Heart Rate=>${hr}")
                        }

                        else -> {}
                    }
                }
        }
        lifecycleScope.launch(Dispatchers.IO) {
            schedulerStartTime = System.currentTimeMillis()
            while (true) {
                Log.i(TAG, "Timer started")
                if (initialWaitingTimeCompleted) {
                    val context = application.applicationContext
                    val heartRateDuration = Duration.ofMinutes(30)
                    val accelerometerDuration = Duration.ofMinutes(5)
                    val startTime = System.currentTimeMillis().toSeconds()
                    val endTime = System.currentTimeMillis().toSeconds()
                    val heartRateData = localDatabaseManager.fetchHeartRateDate(
                        startTime = startTime - heartRateDuration.seconds, endTime = endTime
                    )
                    val accelerometerData = localDatabaseManager.fetchAccelerometerData(
                        startTime = startTime - accelerometerDuration.seconds, endTime = endTime
                    )
                    val result = lifecycleScope.async {
                        sleepStagePredictionHelper.prediction(
                            heartRateData = heartRateData,
                            accelerometerData = accelerometerData,
                            workoutStartTime = System.currentTimeMillis().toSeconds()
                        )
                    }.await()
                    when (result) {
                        SleepStagePredictionOutput.REM -> {
                            io.nextsense.android.main.utils.NotificationManager(context)
                                .showNotification(
                                    title = "REM", message = "This is lucid night notification."
                                )
                        }

                        else -> {
                            Log.i(TAG, "Model Result=>${result}")
                        }
                    }
                    val predictionEntity = PredictionEntity(
                        prediction = result?.value ?: 0,
                        timeStamp = startTime,
                        date = TimeUnit.SECONDS.toMillis(startTime).toFormattedDateString(),
                        startDate = startTime,
                        endDate = endTime
                    )
                    try {
                        localDatabaseManager.savePrediction(
                            predictionEntity
                        )
                    } catch (e: Exception) {
                        Log.i(TAG, "Save prediction error=>${e}")
                    }
                } else {
                    // Calculate the elapsed time in milliseconds
                    val elapsedTime: Long = System.currentTimeMillis() - schedulerStartTime
                    initialWaitingTimeCompleted = elapsedTime >= initialWaitingTime
                }
                delay(dataCheckingPeriod)
                Log.i(TAG, "Timer end")
            }
        }
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
            if (it.sensor == accelerometer) {
                val timestamp = System.currentTimeMillis()
                // Check if enough time has passed since the last saved data or it's the first data
                if (timestamp - lastSavedTimestamp >= MILLISECONDS_PER_SECOND || lastSavedTimestamp == 0L) {
                    val x = (it.values?.getOrNull(0) ?: 0).toDouble()
                    val y = (it.values?.getOrNull(1) ?: 0).toDouble()
                    val z = (it.values?.getOrNull(2) ?: 0f).toDouble()
                    saveAccelerometerData(timestamp, x, y, z)
                    // Update the last saved timestamp
                    lastSavedTimestamp = timestamp
                    Log.i(TAG, "Accelerometer=>X:${x}, y:${y}, z:${z}")
                }
            }
        }
    }

    override fun onAccuracyChanged(p0: Sensor?, p1: Int) {
    }

    private fun saveAccelerometerData(timestamp: Long, x: Double, y: Double, z: Double) {
        lifecycleScope.launch(Dispatchers.IO) {
            try {
                val accelerometerEntity = AccelerometerEntity(
                    x = x, y = y, z = z, createAt = timestamp.toSeconds()
                )
                localDatabaseManager.accelerometerDao?.insertAll(accelerometerEntity)
            } catch (e: Exception) {
                Log.i(TAG, "${e.message}")
            }
        }
    }

    private fun saveHeartRateData(heartRate: Double) {
        lifecycleScope.launch(Dispatchers.IO) {
            try {
                val heartRateEntity = HeartRateEntity(
                    heartRate = heartRate, createAt = System.currentTimeMillis().toSeconds()
                )
                localDatabaseManager.heartRateDao?.insertAll(heartRateEntity)
            } catch (e: Exception) {
                Log.i(TAG, "${e.message}")
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            sensorManager.unregisterListener(this)
            removeOngoingActivityNotification()
        } catch (e: Exception) {
            Log.i(TAG, "${e.message}")
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