package io.nextsense.android.main.db

import androidx.room.AutoMigration
import androidx.room.Database
import androidx.room.RenameColumn
import androidx.room.RoomDatabase
import androidx.room.migration.AutoMigrationSpec
import androidx.sqlite.db.SupportSQLiteDatabase

@Database(
    entities = [HeartRateEntity::class, AccelerometerEntity::class, PredictionEntity::class, NotificationEntity::class],
    version = 3,
    autoMigrations = [
        AutoMigration(
            from = 2, to = 3, spec = LucidAppDatabase.LucidAppDatabaseAutoMigration::class
        ),
    ]
)
abstract class LucidAppDatabase : RoomDatabase() {
    abstract fun heartRateDao(): HeartRateDao
    abstract fun accelerometerDao(): AccelerometerDao
    abstract fun predictionDao(): PredictionDao
    abstract fun notificationDao(): NotificationDao

    @RenameColumn(
        tableName = "HeartRateEntity", fromColumnName = "createAt", toColumnName = "createdAt"
    )
    @RenameColumn(
        tableName = "AccelerometerEntity", fromColumnName = "createAt", toColumnName = "createdAt"
    )
    @RenameColumn(
        tableName = "NotificationEntity", fromColumnName = "createAt", toColumnName = "createdAt"
    )
    @RenameColumn(
        tableName = "PredictionEntity", fromColumnName = "createAt", toColumnName = "createdAt"
    )
    class LucidAppDatabaseAutoMigration : AutoMigrationSpec {
        @Override
        override fun onPostMigrate(db: SupportSQLiteDatabase) {
            // Invoked once auto migration is done
        }
    }
}