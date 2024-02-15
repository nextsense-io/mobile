package io.nextsense.android.main.data

import android.content.Context
import androidx.room.Room
import io.nextsense.android.main.db.LucidAppDatabase

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
}