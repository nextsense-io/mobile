package io.nextsense.android.budz.manager.device

import android.content.Context
import com.airoha.sdk.AirohaConnector
import com.airoha.sdk.AirohaSDK
import com.airoha.sdk.api.message.AirohaBaseMsg
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update
import javax.inject.Inject
import javax.inject.Singleton

enum class DeviceState {
    DISCONNECTED,
    BONDED,
    CONNECTED_AIROHA,
    CONNECTED_AIROHA_WRONG_ROLE,
    READY,
    CONNECTED_BLE
}

@Singleton
class DeviceManager @Inject constructor(@ApplicationContext private val context: Context) {

    private val _airohaDeviceConnector = AirohaSDK.getInst().airohaDeviceConnector
    val deviceState = MutableStateFlow(DeviceState.DISCONNECTED)
    private var _devicePresenter: DeviceSearchPresenter? = null

    private val _airohaConnectionListener: AirohaConnector.AirohaConnectionListener =
        object: AirohaConnector.AirohaConnectionListener {
            override fun onStatusChanged(newStatus: Int) {
                when (newStatus) {
                    AirohaConnector.CONNECTED -> {
                        deviceState.update { DeviceState.CONNECTED_AIROHA }
                    }
                    AirohaConnector.CONNECTED_WRONG_ROLE -> {
                        deviceState.value = DeviceState.CONNECTED_AIROHA_WRONG_ROLE
                    }
                    AirohaConnector.DISCONNECTED -> {
                        deviceState.value = DeviceState.DISCONNECTED
                    }
                }
            }

            override fun onDataReceived(data: AirohaBaseMsg?) {
                // TODO(eric): Route to parse data based on message type
            }
        }
    init {
        _airohaDeviceConnector.registerConnectionListener(_airohaConnectionListener)
        _devicePresenter = DeviceSearchPresenter(context)
    }

    fun isAirohaDeviceBonded(): Boolean {
        val bonded: Boolean = _devicePresenter?.findAirohaDevice() ?: false
        deviceState.value = if (bonded) DeviceState.BONDED else DeviceState.DISCONNECTED
        return bonded
    }

    suspend fun connectDevice() {
        if (deviceState.value != DeviceState.BONDED) {
            val bonded = isAirohaDeviceBonded()
            if (!bonded) {
                return
            }
        }
        connectAirohaDevice()
        deviceState.collect { deviceState ->
            if (deviceState == DeviceState.CONNECTED_AIROHA) {
                // Connect to BLE
                // TODO(eric): Implement BLE connection
            }
        }
    }

    fun disconnectDevice() {
        _devicePresenter?.destroy()
        val airohaDeviceConnector = AirohaSDK.getInst().airohaDeviceConnector
        airohaDeviceConnector.unregisterConnectionListener(_airohaConnectionListener)
    }

    private fun connectAirohaDevice() {
        _devicePresenter?.connectBoundDevice()
    }
}