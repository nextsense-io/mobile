package io.nextsense.android.main.db

import androidx.room.AutoMigration
import androidx.room.Database
import androidx.room.RoomDatabase

@Database(
    entities = [HeartRateEntity::class, AccelerometerEntity::class, PredictionEntity::class, NotificationEntity::class],
    version = 2,
    autoMigrations = [AutoMigration(from = 1, to = 2)]
)
abstract class LucidAppDatabase : RoomDatabase() {
    abstract fun heartRateDao(): HeartRateDao
    abstract fun accelerometerEntity(): AccelerometerDao
    abstract fun predictionEntity(): PredictionDao
    abstract fun notificationEntity(): NotificationDao
}