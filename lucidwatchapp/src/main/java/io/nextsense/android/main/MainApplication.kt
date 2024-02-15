package io.nextsense.android.main

import android.app.Application
import io.nextsense.android.main.data.HealthServicesRepository
import io.nextsense.android.main.data.LocalDatabaseManager

const val TAG = "Lucid Reality Application"
const val PERMISSION = android.Manifest.permission.BODY_SENSORS

class MainApplication : Application() {
    val healthServicesRepository by lazy { HealthServicesRepository(this) }
    val localDatabaseManager by lazy { LocalDatabaseManager(this) }
}
