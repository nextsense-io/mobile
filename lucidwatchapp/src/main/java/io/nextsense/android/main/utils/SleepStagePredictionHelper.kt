package io.nextsense.android.main.utils

import android.content.Context
import android.util.Log
import io.nextsense.android.main.TAG
import io.nextsense.android.main.db.AccelerometerEntity
import io.nextsense.android.main.db.HeartRateEntity
import io.nextsense.android.main.db.getAngle
import org.tensorflow.lite.Interpreter
import org.tensorflow.lite.support.common.FileUtil
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.pow
import kotlin.math.roundToInt
import kotlin.math.sqrt

class SleepStagePredictionHelper(val context: Context) {
    /// past 30 minutes
    private val heartRateSamplesNeeded: Int = 1800

    /// past 5 minutes
    private val accelerometerSamplesNeeded: Int = 300

    fun prediction(
        workoutStartTime: Long,
        heartRateData: List<HeartRateEntity>,
        accelerometerData: List<AccelerometerEntity>
    ): SleepStagePredictionOutput? {
        val currentTime = System.currentTimeMillis().toString()
        Log.i(TAG, "Input Data HR: $heartRateData")
        Log.i(
            TAG,
            "Input Data ACC: ${accelerometerData.map { "${it.createAt}, ${it.x}, ${it.y}, ${it.z}, ${it.getAngle()}" }}"
        )

        val interpolateHRData = interpolateHeartRate(
            data = heartRateData,
            workoutStartTime = workoutStartTime,
            samplesNeeded = heartRateSamplesNeeded
        )
        val normalizedHRData =
            normalizeDataUsingMeanAndStd(interpolateHRData.map { it.heartRate ?: 0.0 })
        Log.i(TAG, "Interpolate Data HR: ${interpolateHRData.take(200)}")
        Log.i(TAG, "Normalized Data HR: ${normalizedHRData.take(200)}")

        // Normalise accelerometer data here
        val interpolateAccelerometerData = interpolateAccelerometerData(
            data = accelerometerData, samplesNeeded = accelerometerSamplesNeeded
        )

        Log.i(TAG, "Interpolate Data ACC: ${interpolateAccelerometerData.take(200)}")

        val differencesAccelerometer =
            interpolateAccelerometerData.zipWithNext { a, b -> kotlin.math.abs(a - b) }

        val differencesAccelerometerList = if (differencesAccelerometer.size < 300) {
            listOf(0.0) + differencesAccelerometer
        } else {
            differencesAccelerometer
        }
        Log.i(TAG, "Difference ACC: ${differencesAccelerometerList.take(200)}")
        val normalizedDifference = normalizeDataUsingMeanAndStd(differencesAccelerometerList)
        Log.i(TAG, "Normalized Data ACC Diff: ${normalizedDifference.take(200)}")
        val combineData =
            (normalizedHRData.asReversed() + normalizedDifference.asReversed()).toDoubleArray()

        val tfliteModel: Interpreter? = try {
            Interpreter(
                FileUtil.loadMappedFile(
                    context, MODEL_FILE
                )
            )
        } catch (e: Exception) {
            Log.i(TAG, "Failed to load core ml model: $e")
            return null
        }

        tfliteModel?.let { mlModel ->
            try {
                val predictionData = combineData.map { it.toFloat() }.toTypedArray()
                val inputDataArray = Array(1) { Array(predictionData.size) { FloatArray(1) } }
                // Fill the inputDataArray with data [[0],[index],[0]]
                predictionData.forEachIndexed { index, floats ->
                    inputDataArray[0][index][0] = floats
                }
                val output = Array(1) { FloatArray(3) }
                mlModel.run(inputDataArray, output)
                Log.i(TAG, "Output=>${output[0][0]} ${output[0][1]} ${output[0][2]}")
                return output.predictSleepStage()
            } catch (e: Exception) {
                Log.i(TAG, "Error: $e")
            }
        }
        return null
    }


    private fun normalizeDataUsingMeanAndStd(data: List<Double>): List<Double> {
        if (data.isEmpty()) {
            // Handle the case where data is empty
            return data
        }
        // Calculate mean
        val mean = data.sum() / data.size.toDouble()
        // Calculate standard deviation
        val squaredDifferences = data.map { (it - mean).pow(2) }
        val sumSquaredDifferences = squaredDifferences.sum()
        val standardDeviation = sqrt(sumSquaredDifferences / data.size.toDouble())
        // Normalize the data
        return data.map { (it - mean) / (standardDeviation + 0.000001) }
    }

    private fun interpolateHeartRate(
        data: List<HeartRateEntity>, workoutStartTime: Long, samplesNeeded: Int
    ): List<HeartRateEntity> {
        val interpolatedData = mutableListOf<HeartRateEntity>()
        for (i in 0 until data.size - 1) {
            val startTime = data[i].createAt ?: 0
            val endTime = data[i + 1].createAt ?: 0
            val startRate = data[i].heartRate ?: 0.0
            val endRate = data[i + 1].heartRate ?: 0.0
            val timeDiff = endTime - startTime
            val rateDiff = endRate - startRate
            val slope = rateDiff / timeDiff
            if (i == 0) {
                for (j in workoutStartTime until startTime) {
                    val interpolatedTime = workoutStartTime + j
                    interpolatedData.add(
                        HeartRateEntity(
                            createAt = interpolatedTime, heartRate = startRate
                        )
                    )
                }
            }

            for (j in 0 until timeDiff.toInt()) {
                val interpolatedTime = startTime + j
                val interpolatedRate = startRate + slope * j
                interpolatedData.add(
                    HeartRateEntity(
                        createAt = interpolatedTime,
                        heartRate = interpolatedRate.roundToInt().toDouble()
                    )
                )
            }
        }

        // Add last data point if it exists
        data.lastOrNull()?.let { lastData ->
            interpolatedData.add(lastData)
        }

        val currentSamples = interpolatedData.size
        if (currentSamples < samplesNeeded) {
            interpolatedData.lastOrNull()?.let { lastData ->
                val lastTime = lastData.createAt ?: 0
                val lastValue = lastData.heartRate ?: 0.0
                interpolatedData.addAll((1..samplesNeeded - currentSamples).map {
                    HeartRateEntity(
                        createAt = lastTime + it, heartRate = lastValue.roundToInt().toDouble()
                    )
                })
            }
        }
        return interpolatedData
    }


    private fun interpolateAccelerometerData(
        data: List<AccelerometerEntity>, samplesNeeded: Int
    ): List<Double> {
        val resultArray = MutableList(samplesNeeded) { 0.0 }

        var currentIndex = 0
        var lastTimestamp = data.firstOrNull()?.createAt ?: 0L

        for (datum in data) {
            val timeDiff = (datum.createAt - lastTimestamp).toInt()

            // Check if there's a gap between current and last timestamp
            if (timeDiff > 1) {
                // Fill in missing data with zero values at the specific index
                repeat(timeDiff - 1) {
                    resultArray[currentIndex] = 0.0
                    currentIndex++
                }
            }

            // Add current data to result array
            try {
                resultArray[currentIndex] = datum.getAngle()
            } catch (_: Exception) {
            }
            currentIndex++
            lastTimestamp = datum.createAt
        }

        // Fill the remaining slots with zero values if needed
        while (currentIndex < samplesNeeded) {
            resultArray[currentIndex] = 0.0
            currentIndex++
        }

        return resultArray
    }

    companion object {
        const val MODEL_FILE = "cnn_2100_0103.tflite"
    }
}

sealed class SleepStagePredictionOutput(val value: Int) {
    data object NREM : SleepStagePredictionOutput(0)
    data object REM : SleepStagePredictionOutput(1)
    data object WAKE : SleepStagePredictionOutput(2)
}

fun Array<FloatArray>.predictSleepStage(): SleepStagePredictionOutput {
    var maxIndexColumn = 0
    var maxValue = this[0][0]

    for (i in this.indices) {
        for (j in this[i].indices) {
            if (this[i][j] > maxValue) {
                maxValue = this[i][j]
                maxIndexColumn = j
            }
        }
    }

    return when (maxIndexColumn) {
        0 -> SleepStagePredictionOutput.NREM
        1 -> SleepStagePredictionOutput.REM
        2 -> SleepStagePredictionOutput.WAKE
        else -> throw IllegalArgumentException("Invalid sleep stage prediction output")
    }
}

fun Long.toFormattedDateString(): String {
    val dateFormat = SimpleDateFormat("dd/MM/yyyy hh:mm:ss a", Locale.getDefault())
    val date = Date(this)
    return dateFormat.format(date)
}



