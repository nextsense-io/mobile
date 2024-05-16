package io.nextsense.android.budz.manager.device

import android.content.Context
import android.util.Log
import com.airoha.sdk.AirohaConnector
import com.airoha.sdk.AirohaSDK
import com.airoha.sdk.api.control.AirohaDeviceListener
import com.airoha.sdk.api.message.AirohaBaseMsg
import com.airoha.sdk.api.message.AirohaEQPayload
import com.airoha.sdk.api.utils.AirohaEQBandType
import com.airoha.sdk.api.utils.AirohaStatusCode
import dagger.hilt.android.qualifiers.ApplicationContext
import io.nextsense.android.budz.ui.screens.DeviceSettingsViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update
import java.util.LinkedList
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
    private var _devicePresenter: DeviceSearchPresenter? = null
    // Frequencies that can be set in the equalizer.
    private val _eqFrequencies =
        floatArrayOf(200f, 280f, 400f, 550f, 770f, 1000f, 2000f, 4000f, 8000f, 16000f)
    private var _targetGains: FloatArray = floatArrayOf(0f,0f,0f,0f,0f,0f,0f,0f,0f,0f)

    val deviceState = MutableStateFlow(DeviceState.DISCONNECTED)
    val equalizerState = MutableStateFlow(FloatArray(10) { 0f })

    private val _airohaConnectionListener: AirohaConnector.AirohaConnectionListener =
        object: AirohaConnector.AirohaConnectionListener {
            override fun onStatusChanged(newStatus: Int) {
                when (newStatus) {
                    AirohaConnector.CONNECTED -> {
                        deviceState.update { DeviceState.CONNECTED_AIROHA }
                    }
                    AirohaConnector.CONNECTED_WRONG_ROLE -> {
                        deviceState.update { DeviceState.CONNECTED_AIROHA_WRONG_ROLE }
                    }
                    AirohaConnector.DISCONNECTED -> {
                        deviceState.update { DeviceState.DISCONNECTED }
                    }
                }
            }

            override fun onDataReceived(data: AirohaBaseMsg?) {
                // TODO(eric): Route to parse data based on message type
            }
        }

    private val airohaDeviceListener = object : AirohaDeviceListener {

        private val tag = DeviceSettingsViewModel::class.java.simpleName

        override fun onRead(code: AirohaStatusCode, msg: AirohaBaseMsg) {
        }

        override fun onChanged(code: AirohaStatusCode, msg: AirohaBaseMsg) {
            try {
                if (code == AirohaStatusCode.STATUS_SUCCESS) {
                    equalizerState.value = _targetGains
                } else {
                    _targetGains = equalizerState.value
                    Log.w(tag, "Equalizer settings not changed: $code.")
                }
            } catch (e: Exception) {
                _targetGains = equalizerState.value
                Log.w(tag, "Equalizer settings error: ${e.message}.")
            }
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

    fun changeEqualizer(gains: FloatArray) {
        _targetGains = gains
        val params = LinkedList<AirohaEQPayload.EQIDParam>()
        for (i in _eqFrequencies.indices) {
            val bandInfo = AirohaEQPayload.EQIDParam()
            val freq: Float = _eqFrequencies[i]
            val gain = gains[i]
            val q = 2f

            bandInfo.bandType = AirohaEQBandType.BAND_PASS.value
            bandInfo.frequency = freq
            bandInfo.gainValue = gain
            bandInfo.qValue = q

            params.add(bandInfo)
        }

        val eqPayload = AirohaEQPayload()
        eqPayload.allSampleRates = intArrayOf(44100, 48000)
        eqPayload.bandCount = 10f
        eqPayload.iirParams = params
        eqPayload.index = 101

        AirohaSDK.getInst().airohaEQControl.setEQSetting(
            101,
            eqPayload,
            /*=saveOrNot=*/true,
            airohaDeviceListener
        )
    }

    private fun connectAirohaDevice() {
        _devicePresenter?.connectBoundDevice()
    }
}