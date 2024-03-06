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
import io.nextsense.android.main.utils.SleepStagePredictionHelper
import io.nextsense.android.main.utils.SleepStagePredictionOutput
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
    @Assisted appContext: Context,
    @Assisted params: WorkerParameters
) : CoroutineWorker(appContext, params) {

    override suspend fun doWork(): Result {
        // Get the get service status from the input data
        val isServiceRunning = inputData.getBoolean(IS_SERVICE_RUNNING, false)
        return try {
            val heartRateDuration = Duration.ofMinutes(30)
            val accelerometerDuration = Duration.ofMinutes(5)
            while (isServiceRunning) {
                Log.d(TAG, "Timer task start")
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
                            io.nextsense.android.main.utils.NotificationManager(applicationContext)
                                .showNotification(
                                    title = "REM", message = "This is lucid night notification."
                                )
                        }

                        else -> {
                            Log.i(io.nextsense.android.main.TAG, "Model Result=>${result}")
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
                        Log.i(io.nextsense.android.main.TAG, "Save prediction error=>${e}")
                    }
                }
                Log.d(TAG, "Timer task end")
                delay(TimeUnit.SECONDS.toMillis(30))
            }
            Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "Error PredictionWork", e)
            Result.failure()
        }
    }

    companion object {
        const val TAG = "PredictionWork"
    }
}