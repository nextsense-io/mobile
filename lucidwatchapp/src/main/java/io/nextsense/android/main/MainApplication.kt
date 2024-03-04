package io.nextsense.android.main

import android.app.Application
import dagger.hilt.android.HiltAndroidApp

const val TAG = "Lucid Reality Application"
val PERMISSIONS = listOf(
    android.Manifest.permission.BODY_SENSORS, android.Manifest.permission.POST_NOTIFICATIONS
)

@HiltAndroidApp
class MainApplication : Application()
