package io.nextsense.android.main.data

import android.content.Context
import androidx.room.Room
import io.nextsense.android.main.db.AccelerometerEntity
import io.nextsense.android.main.db.HeartRateEntity
import io.nextsense.android.main.db.LucidAppDatabase
import io.nextsense.android.main.db.NotificationEntity
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
    val accelerometerDao = db?.accelerometerDao()
    val predictionDao = db?.predictionDao()
    val notificationDao = db?.notificationDao()


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

    fun saveNotification(notificationEntity: NotificationEntity) {
        notificationDao?.insert(notificationEntity)
    }

    fun clearAllTables() {
        try {
            db?.clearAllTables()
        } catch (e: Exception) {
            e.printStackTrace();
        }
    }
}