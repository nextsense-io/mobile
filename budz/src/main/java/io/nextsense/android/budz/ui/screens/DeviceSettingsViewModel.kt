package io.nextsense.android.budz.ui.screens

import android.util.Log
import androidx.lifecycle.ViewModel
import com.airoha.sdk.AirohaSDK
import com.airoha.sdk.api.control.AirohaDeviceListener
import com.airoha.sdk.api.message.AirohaBaseMsg
import com.airoha.sdk.api.message.AirohaEQPayload
import com.airoha.sdk.api.message.AirohaEQPayload.EQIDParam
import com.airoha.sdk.api.utils.AirohaEQBandType
import com.airoha.sdk.api.utils.AirohaStatusCode
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.LinkedList
import javax.inject.Inject

data class DeviceSettingsState(
    val message: String,
)

@HiltViewModel
class DeviceSettingsViewModel @Inject constructor(): ViewModel() {

    private val _uiState = MutableStateFlow(DeviceSettingsState(""))
    // Frequencies that can be set in the equalizer.
    private val _freqs =
        floatArrayOf(200f, 280f, 400f, 550f, 770f, 1000f, 2000f, 4000f, 8000f, 16000f)

    val uiState: StateFlow<DeviceSettingsState> = _uiState.asStateFlow()

    fun changeEqualizer(gains: FloatArray) {
        val params = LinkedList<EQIDParam>()
        for (i in _freqs.indices) {
            val bandInfo = EQIDParam()
            val freq: Float = _freqs[i]
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

    private val airohaDeviceListener = object : AirohaDeviceListener {

        private val tag = DeviceSettingsViewModel::class.java.simpleName

        override fun onRead(code: AirohaStatusCode, msg: AirohaBaseMsg) {
        }

        override fun onChanged(code: AirohaStatusCode, msg: AirohaBaseMsg) {
            try {
                if (code == AirohaStatusCode.STATUS_SUCCESS) {
                    _uiState.value = _uiState.value.copy(message = "Equalizer settings changed.")
                } else {
                    _uiState.value = _uiState.value.copy(message =
                        "Equalizer settings not changed: $code.")
                }
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(message =
                "Equalizer settings error: ${e.message}.")
                Log.e(tag, e.message, e)
            }
        }
    }
}