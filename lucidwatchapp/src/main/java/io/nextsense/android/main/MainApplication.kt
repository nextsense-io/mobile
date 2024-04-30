package io.nextsense.android.main

import android.app.Application
import android.os.Build
import androidx.annotation.RequiresApi
import androidx.hilt.work.HiltWorkerFactory
import androidx.work.Configuration
import dagger.hilt.android.HiltAndroidApp
import javax.inject.Inject

const val TAG = "Lucid Reality Application"
val PERMISSIONS = listOf(
    android.Manifest.permission.BODY_SENSORS
)

@RequiresApi(Build.VERSION_CODES.TIRAMISU)
val PERMISSIONS_TIRAMISU = listOf(
    android.Manifest.permission.BODY_SENSORS, android.Manifest.permission.POST_NOTIFICATIONS
)

@HiltAndroidApp
class MainApplication : Application(), Configuration.Provider {

    @Inject
    lateinit var workerFactory: HiltWorkerFactory
    override val workManagerConfiguration: Configuration
        get() = Configuration.Builder()
            .setWorkerFactory(workerFactory)
            .build()
}

