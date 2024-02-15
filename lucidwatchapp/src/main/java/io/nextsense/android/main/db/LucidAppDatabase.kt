package io.nextsense.android.main.db

import androidx.room.Database
import androidx.room.RoomDatabase

@Database(entities = [HeartRateEntity::class, AccelerometerEntity::class], version = 1)
abstract class LucidAppDatabase : RoomDatabase() {
    abstract fun heartRateDao(): HeartRateDao
    abstract fun accelerometerEntity(): AccelerometerDao
}