package io.nextsense.android.main.service

import android.content.Context
import android.util.Log
import androidx.hilt.work.HiltWorker
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import dagger.assisted.Assisted
import dagger.assisted.AssistedInject
import io.nextsense.android.main.data.LocalDatabaseManager
import io.nextsense.android.main.db.PredictionEntity
import io.nextsense.android.main.utils.Logger
import io.nextsense.android.main.utils.NotificationManager
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
    private val logger: Logger,
    @Assisted appContext: Context,
    @Assisted params: WorkerParameters
) : CoroutineWorker(appContext, params) {

    //It should show up next notification after 20 minutes
    private var lastNotificationShowUpTime = 0L
    private val rescheduleTime = TimeUnit.MINUTES.toMillis(1)

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
                                NotificationManager(
                                    applicationContext
                                ).showNotification(
                                    title = "REM",
                                    message = "This is lucid night notification.",
                                )
                                lastNotificationShowUpTime = System.currentTimeMillis()
                            }
                        }

                        else -> {
                            Log.i(io.nextsense.android.main.TAG, "Model Result=>${result}")
                        }
                    }
                    val predictionEntity = PredictionEntity(
                        prediction = result?.value ?: 0,
                        createAt = startTime,
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
                delay(rescheduleTime)
            }
            Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "Error PredictionWork", e)
            Result.failure()
        }
    }

    /**
     * Checks the last 10 records with a prediction of 1 (REM) before showing a notification.
     * Subsequent notifications are scheduled to appear 20 minutes after the first one.
     */
    private fun shouldShowNotification(): Boolean {
        val isREMInRecentRecords =
            localDatabaseManager.predictionDao?.isREMInRecentRecords() ?: false
        // Calculate the elapsed time in milliseconds
        val elapsedTime: Long = System.currentTimeMillis() - lastNotificationShowUpTime
        return isREMInRecentRecords && (lastNotificationShowUpTime == 0L || elapsedTime >= minutesToMilliseconds(
            20
        ))
    }

    companion object {
        const val TAG = "PredictionWork"
    }
}