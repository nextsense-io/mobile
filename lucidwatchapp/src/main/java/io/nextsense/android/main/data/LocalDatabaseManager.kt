package io.nextsense.android.main.data

import android.content.Context
import androidx.room.Room
import io.nextsense.android.main.db.AccelerometerEntity
import io.nextsense.android.main.db.HeartRateEntity
import io.nextsense.android.main.db.LucidAppDatabase
import io.nextsense.android.main.utils.toSeconds
import java.time.Duration

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

    fun fetchHeartRateDate(duration: Duration): List<HeartRateEntity> {
        val startTime = System.currentTimeMillis().toSeconds() - duration.seconds
        val endTime = System.currentTimeMillis().toSeconds()
        return heartRateDao?.findByDateRange(startTime = startTime, endTime = endTime) ?: listOf()
    }

    fun fetchAccelerometerData(duration: Duration): List<AccelerometerEntity> {
        val startTime = System.currentTimeMillis().toSeconds() - duration.seconds
        val endTime = System.currentTimeMillis().toSeconds()
        return accelerometerDao?.findByDateRange(startTime = startTime, endTime = endTime)
            ?: listOf()
    }
}