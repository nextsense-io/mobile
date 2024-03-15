package io.nextsense.android.main.data

import android.content.Context
import androidx.room.Room
import io.nextsense.android.main.db.AccelerometerEntity
import io.nextsense.android.main.db.HeartRateEntity
import io.nextsense.android.main.db.LucidAppDatabase
import io.nextsense.android.main.db.PredictionEntity

class LocalDatabaseManager(context: Context) {

    private val db = try {
        Room.databaseBuilder(
            context, LucidAppDatabase::class.java, "lucidDB"
        ).build()
    } catch (e: Exception) {
        e.printStackTrace();
        null
    }
    val heartRateDao = db?.heartRateDao()
    val accelerometerDao = db?.accelerometerEntity()
    val predictionDao = db?.predictionEntity()

    fun fetchHeartRateDate(startTime: Long, endTime: Long): List<HeartRateEntity> {
        return heartRateDao?.findByDateRange(
            startTime = startTime, endTime = endTime
        ) ?: listOf()
    }

    fun fetchAccelerometerData(startTime: Long, endTime: Long): List<AccelerometerEntity> {
        return accelerometerDao?.findByDateRange(
            startTime = startTime, endTime = endTime
        ) ?: listOf()
    }

    fun savePrediction(predictionEntity: PredictionEntity) {
        predictionDao?.insertAll(predictionEntity)
    }

    fun clearAllTables() {
        try {
            db?.clearAllTables()
        } catch (e: Exception) {
            e.printStackTrace();
        }
    }
}