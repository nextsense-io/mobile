package io.nextsense.android.budz.ui.screens

import android.content.Context
import androidx.lifecycle.ViewModel
import com.airoha.sdk.AirohaConnector
import com.airoha.sdk.AirohaSDK
import com.airoha.sdk.api.message.AirohaBaseMsg
import dagger.hilt.android.lifecycle.HiltViewModel
import io.nextsense.android.budz.manager.device.DeviceSearchPresenter
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject

data class DeviceConnectionState(
    val connecting: Boolean = false,
    val connected: Boolean = false,
    val connectedWrongRole: Boolean = false
)

@HiltViewModel
class DeviceConnectionViewModel @Inject constructor(): ViewModel() {

    private val _uiState = MutableStateFlow(DeviceConnectionState())
    private val _airohaDeviceConnector = AirohaSDK.getInst().airohaDeviceConnector

    val uiState: StateFlow<DeviceConnectionState> = _uiState.asStateFlow()

    private var _devicePresenter: DeviceSearchPresenter? = null

    private val _airohaConnectionListener: AirohaConnector.AirohaConnectionListener =
        object: AirohaConnector.AirohaConnectionListener {
            override fun onStatusChanged(newStatus: Int) {
                when (newStatus) {
                    AirohaConnector.CONNECTED -> {
                        _uiState.value = _uiState.value.copy(connected = true, connecting = false)
                    }
                    AirohaConnector.CONNECTED_WRONG_ROLE -> {
                        _uiState.value = _uiState.value.copy(connectedWrongRole = true)
                    }
                    AirohaConnector.DISCONNECTED -> {
                        _uiState.value = DeviceConnectionState()
                    }
                }
            }

            override fun onDataReceived(data: AirohaBaseMsg?) {
                // Nothing to do while connecting.
            }
    }

    fun initPresenter(context: Context) {
        _airohaDeviceConnector.registerConnectionListener(_airohaConnectionListener)
        _devicePresenter = DeviceSearchPresenter(context)
    }

    fun connectBoundDevice() {
        _uiState.value = _uiState.value.copy(connecting = true)
        _devicePresenter?.connectBoundDevice()
    }

    fun destroyPresenter() {
        _devicePresenter?.destroy()
        val airohaDeviceConnector = AirohaSDK.getInst().airohaDeviceConnector
        airohaDeviceConnector.unregisterConnectionListener(_airohaConnectionListener)
    }
}