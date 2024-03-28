package io.nextsense.android.main.service

import android.annotation.SuppressLint
import android.content.Context
import android.media.MediaPlayer
import android.net.Uri
import android.util.Log
import androidx.hilt.work.HiltWorker
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import dagger.assisted.Assisted
import dagger.assisted.AssistedInject
import io.nextsense.android.main.data.LocalDatabaseManager
import io.nextsense.android.main.data.RealityTest
import io.nextsense.android.main.db.NotificationEntity
import io.nextsense.android.main.db.PredictionEntity
import io.nextsense.android.main.lucid.R
import io.nextsense.android.main.utils.Logger
import io.nextsense.android.main.utils.NotificationManager
import io.nextsense.android.main.utils.SharedPreferencesData
import io.nextsense.android.main.utils.SharedPreferencesHelper
import io.nextsense.android.main.utils.SleepStagePredictionHelper
import io.nextsense.android.main.utils.SleepStagePredictionOutput
import io.nextsense.android.main.utils.minutesToMilliseconds
import io.nextsense.android.main.utils.toFormattedDateString
import io.nextsense.android.main.utils.toSeconds
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import java.time.Duration
import java.util.concurrent.TimeUnit

const val IS_SERVICE_RUNNING = "isServiceRunning"
const val REM_PREDICTION_WORK = "remPredictionWork"

@HiltWorker
class PredictionWork @AssistedInject constructor(
    private val localDatabaseManager: LocalDatabaseManager,
    private val sleepStagePredictionHelper: SleepStagePredictionHelper,
    private val sharedPreferencesHelper: SharedPreferencesHelper,
    private val logger: Logger,
    @Assisted appContext: Context,
    @Assisted params: WorkerParameters
) : CoroutineWorker(appContext, params) {

    //It should show up next notification after 20 minutes
    private var lastNotificationShowUpTime = 0L


    override suspend fun doWork(): Result {
        // Get the get service status from the input data
        val isServiceRunning = inputData.getBoolean(IS_SERVICE_RUNNING, false)
        return try {
            val heartRateDuration = Duration.ofMinutes(30)
            val accelerometerDuration = Duration.ofMinutes(5)
            while (isServiceRunning) {
                logger.log("Timer task start")
                withContext(Dispatchers.IO) {
                    val startTime = System.currentTimeMillis().toSeconds()
                    val endTime = System.currentTimeMillis().toSeconds()
                    val heartRateData = localDatabaseManager.fetchHeartRateDate(
                        startTime = startTime - heartRateDuration.seconds, endTime = endTime
                    )
                    val accelerometerData = localDatabaseManager.fetchAccelerometerData(
                        startTime = startTime - accelerometerDuration.seconds, endTime = endTime
                    )
                    val result = async {
                        sleepStagePredictionHelper.prediction(
                            heartRateData = heartRateData,
                            accelerometerData = accelerometerData,
                            workoutStartTime = System.currentTimeMillis().toSeconds()
                        )
                    }.await()
                    when (result) {
                        SleepStagePredictionOutput.REM -> {
                            if (shouldShowNotification()) {
                                showNotification()
                            }
                        }

                        else -> {
                            Log.i(io.nextsense.android.main.TAG, "Model Result=>${result}")
                        }
                    }
                    val predictionEntity = PredictionEntity(
                        prediction = result?.value ?: 0,
                        createdAt = startTime,
                        date = TimeUnit.SECONDS.toMillis(startTime).toFormattedDateString(),
                        startDate = startTime,
                        endDate = endTime
                    )
                    try {
                        localDatabaseManager.savePrediction(
                            predictionEntity
                        )
                    } catch (e: Exception) {
                        logger.log("Save prediction error=>${e}")
                    }
                }
                logger.log("Timer task end")
                delay(PredictionConfig.rescheduleTime)
            }
            Result.success()
        } catch (e: Exception) {
            logger.log("Error PredictionWork:$e")
            Result.failure()
        }
    }

    /**
     * Checks the last 5 records with a prediction of 1 (REM) before showing a notification.
     * Subsequent notifications are scheduled to appear 20 minutes after the first one.
     */
    private fun shouldShowNotification(): Boolean {
        val isREMInRecentRecords =
            localDatabaseManager.predictionDao?.isREMInRecentRecords(numberOfRecords = PredictionConfig.NUMBER_OF_RECORDS)
                ?: false
        // Calculate the elapsed time in milliseconds
        val elapsedTime: Long = System.currentTimeMillis() - lastNotificationShowUpTime
        return isREMInRecentRecords && (lastNotificationShowUpTime == 0L || elapsedTime >= minutesToMilliseconds(
            20
        ))
    }

    /**
     * This function plays the specified sound file
     */
    private fun playNotificationSound(totemSound: String) {
        val resourceId = getRawResourceIdByName(applicationContext, totemSound.lowercase())
        val uri: Uri = if (resourceId != 0) {
            // Resource found, you can use it now
            Uri.parse("android.resource://" + applicationContext.packageName + "/" + resourceId)
            // Now you can use this URI for playing the sound or any other operation
        } else {
            // Resource not found, handle the error accordingly
            Uri.parse(
                "android.resource://" + applicationContext.packageName + "/" + applicationContext.resources.getResourceName(
                    R.raw.air
                )
            )
        }
        try {
            val mediaPlayer = MediaPlayer.create(applicationContext, uri)
            mediaPlayer.setOnCompletionListener { mediaPlayer.release() }
            mediaPlayer.start()
        } catch (e: Exception) {
            logger.log("sound playing error:${e.message}")
        }
    }

    @SuppressLint("DiscouragedApi")
    fun getRawResourceIdByName(context: Context, soundName: String): Int {
        return context.resources.getIdentifier(soundName, "raw", context.packageName)
    }

    private fun showNotification() {
        val soundSettings = sharedPreferencesHelper.getString(
            SharedPreferencesData.LucidSettings.name, ""
        )
        val realityTest = RealityTest.fromJson(soundSettings)
        NotificationManager(
            applicationContext
        ).showNotification(
            title = "Into the Dream Realm",
            message = "You're in the realm of dreams now. Let your imagination soar.",
        )
        // Play the custom sound
        playNotificationSound(realityTest.totemSound)
        lastNotificationShowUpTime = System.currentTimeMillis()
        try {
            localDatabaseManager.saveNotification(
                NotificationEntity(
                    createdAt = lastNotificationShowUpTime.toSeconds(),
                    date = lastNotificationShowUpTime.toFormattedDateString()
                )
            )
        } catch (e: Exception) {
            logger.log("Save notification error=>${e}")
        }
    }
}

object PredictionConfig {
    val initialWaitingTime = minutesToMilliseconds(15)
    val rescheduleTime = TimeUnit.MINUTES.toMillis(1)
    const val NUMBER_OF_RECORDS = 5
    val SENSOR_FREQUENCY = TimeUnit.SECONDS.toMillis(1)
}