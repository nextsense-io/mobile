package io.nextsense.android.budz.ui.screens

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.IBinder
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import io.nextsense.android.airoha.device.AirohaBleManager
import io.nextsense.android.base.utils.RotatingFileLogger
import io.nextsense.android.budz.manager.SessionManager
import io.nextsense.android.budz.service.BudzService
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.launchIn

data class BudzState(
    val budzServiceBound: Boolean = false,
)

abstract class BudzViewModel(
    private val context: Context,
) : ViewModel() {
    private val tag = BudzViewModel::class.java.simpleName
    private var _sessionManager: SessionManager? = null
    private var _airohaBleManager: AirohaBleManager? = null
    private val _budzState = MutableStateFlow(BudzState())

    val budzState: StateFlow<BudzState> = _budzState.asStateFlow()

    val sessionManager: SessionManager
        get() = _sessionManager ?: throw IllegalStateException("SessionManager is not initialized.")
    val airohaBleManager: AirohaBleManager
        get() = _airohaBleManager ?: throw IllegalStateException("AirohaBleManager is not initialized.")

    init {
        connectServiceFlow()
            .flowOn(Dispatchers.IO)
            .launchIn(viewModelScope)
    }

    private fun connectBudzService(serviceConnection: ServiceConnection) {
        val budzServiceIntent = Intent(context, BudzService::class.java)
        context.bindService(budzServiceIntent, serviceConnection, Context.BIND_IMPORTANT)
    }

    private fun connectServiceFlow() = callbackFlow<Boolean> {
        val budzServiceConnection: ServiceConnection = object : ServiceConnection {
            override fun onServiceConnected(className: ComponentName, service: IBinder) {
                val binder: BudzService.LocalBinder = service as BudzService.LocalBinder
                _sessionManager = binder.service.sessionManager
                _airohaBleManager = binder.service.airohaBleManager
               _budzState.value = BudzState(budzServiceBound = true)
                RotatingFileLogger.get().logi(tag, "service bound.")
                trySend(true)
            }

            override fun onServiceDisconnected(componentName: ComponentName) {
                // _budzService = null
                _budzState.value = BudzState(budzServiceBound = false)
                trySend(false)
            }
        }

        connectBudzService(budzServiceConnection)

        awaitClose {
            if (_budzState.value.budzServiceBound) {
                context.unbindService(budzServiceConnection)
                RotatingFileLogger.get().logi(tag, "service unbound.")
            }
        }
    }
}