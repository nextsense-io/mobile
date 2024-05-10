package io.nextsense.android.budz

import android.app.Application
import com.airoha.sdk.AirohaSDK
import com.google.firebase.FirebaseApp
import dagger.hilt.android.HiltAndroidApp
import io.nextsense.android.budz.model.Device

@HiltAndroidApp
class BudzApplication: Application() {

    private var _device: Device? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
        init()
    }

    override fun onTerminate() {
        AirohaSDK.getInst().destroy()
        super.onTerminate()
    }

    private fun init() {
        FirebaseApp.initializeApp(this)
        AirohaSDK.getInst().init(this)
    }

    fun initDevice(name: String?, address: String?) {
        _device = Device(name, address)
    }

    fun getDevice(): Device? {
        return _device
    }

    companion object {
        lateinit var instance: BudzApplication
            private set
    }
}