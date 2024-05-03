package io.nextsense.android.budz

import android.app.Application
import com.google.firebase.FirebaseApp
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class BudzApplication: Application() {

    override fun onCreate() {
        super.onCreate()
        instance = this
        init()
    }

    fun init() {
        FirebaseApp.initializeApp(this)
    }

    companion object {
        lateinit var instance: BudzApplication
            private set
    }
}