package io.nextsense.android.main

import android.app.Application
import io.nextsense.android.main.data.HealthServicesRepository

const val TAG = "Measure Data Sample"
const val PERMISSION = android.Manifest.permission.BODY_SENSORS

class MainApplication : Application() {
    val healthServicesRepository by lazy { HealthServicesRepository(this) }
}
