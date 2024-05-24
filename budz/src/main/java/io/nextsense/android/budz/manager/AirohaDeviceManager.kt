package io.nextsense.android.budz.manager

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.IBinder
import android.util.Log
import com.airoha.libbase.RaceCommand.constant.RaceType
import com.airoha.libutils.Converter
import com.airoha.sdk.AirohaConnector
import com.airoha.sdk.AirohaSDK
import com.airoha.sdk.api.control.AirohaDeviceControl
import com.airoha.sdk.api.control.AirohaDeviceListener
import com.airoha.sdk.api.message.AirohaBaseMsg
import com.airoha.sdk.api.message.AirohaCmdSettings
import com.airoha.sdk.api.message.AirohaEQPayload
import com.airoha.sdk.api.utils.AirohaEQBandType
import com.airoha.sdk.api.utils.AirohaStatusCode
import dagger.hilt.android.qualifiers.ApplicationContext
import io.nextsense.android.airoha.device.AirohaBleManager
import io.nextsense.android.airoha.device.DataStreamRaceCommand
import io.nextsense.android.airoha.device.DeviceSearchPresenter
import io.nextsense.android.base.DeviceState
import io.nextsense.android.base.utils.RotatingFileLogger
import io.nextsense.android.budz.service.BudzService
import io.nextsense.android.budz.ui.activities.MainActivity
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.update
import java.util.LinkedList
import javax.inject.Inject
import javax.inject.Singleton

enum class AirohaDeviceState {
    DISCONNECTED,  // Device is not currently connected.
    BONDED,  // Device is bonded with Bluetooth Classic.
    CONNECTED_AIROHA,  // Device is currently connected with Bluetooth Classic.
    CONNECTED_AIROHA_WRONG_ROLE,  // Device is connected with Bluetooth Classic but with wrong role.
    CONNECTED_BLE,  // Device is currently connected with BLE and Bluetooth Classic.
    READY  // Device is ready to use (Airoha and BLE connected, settings applied).
}

@Singleton
class AirohaDeviceManager @Inject constructor(@ApplicationContext private val context: Context) {

    private val tag = AirohaDeviceManager::class.java.simpleName
    private val _airohaDeviceConnector = AirohaSDK.getInst().airohaDeviceConnector
    private val _foregroundServiceIntent: Intent? = null
    // Frequencies that can be set in the equalizer.
    private val _eqFrequencies =
        floatArrayOf(200f, 280f, 400f, 550f, 770f, 1000f, 2000f, 4000f, 8000f, 16000f)
    // Equalizer gains that are currently being set. _equalizerState is the current state, and will
    // get updated if these are set successfully.
    private val _deviceState = MutableStateFlow(AirohaDeviceState.DISCONNECTED)
    private val _equalizerState = MutableStateFlow(FloatArray(10) { 0f })

    private var _budzServiceBound = false
    private var _budzServiceIntent: Intent? = null
    private var _budzService: BudzService? = null
    private var _budzServiceConnection: ServiceConnection? = null
    private var _airohaBleManager: AirohaBleManager? = null
    private var _devicePresenter: DeviceSearchPresenter? = null
    private var _targetGains: FloatArray = floatArrayOf(0f,0f,0f,0f,0f,0f,0f,0f,0f,0f)

    val deviceState: StateFlow<AirohaDeviceState> = _deviceState.asStateFlow()
    val equalizerState: StateFlow<FloatArray> = _equalizerState.asStateFlow()

    private val _airohaConnectionListener: AirohaConnector.AirohaConnectionListener =
        object: AirohaConnector.AirohaConnectionListener {
            override fun onStatusChanged(newStatus: Int) {
                when (newStatus) {
                    AirohaConnector.CONNECTED -> {
                        _deviceState.update { AirohaDeviceState.CONNECTED_AIROHA }
                    }
                    AirohaConnector.CONNECTED_WRONG_ROLE -> {
                        _deviceState.update { AirohaDeviceState.CONNECTED_AIROHA_WRONG_ROLE }
                    }
                    AirohaConnector.DISCONNECTED -> {
                        _deviceState.update { AirohaDeviceState.DISCONNECTED }
                    }
                }
            }

            override fun onDataReceived(data: AirohaBaseMsg?) {
                // TODO(eric): Route to parse data based on message type
            }
        }

    private val airohaDeviceListener = object : AirohaDeviceListener {

        override fun onRead(code: AirohaStatusCode, msg: AirohaBaseMsg) {
            Log.d(tag, "Read response: ${msg.msgContent}")
            if (code == AirohaStatusCode.STATUS_SUCCESS) {
                val resp = msg.msgContent as ByteArray
                Log.d(tag, "Read response: ${Converter.byte2HerStrReverse(resp)}")
            } else {
                Log.w(tag, "Read error: $code.")
            }
        }

        override fun onChanged(code: AirohaStatusCode, msg: AirohaBaseMsg) {
            Log.d(tag, "Changed response: ${msg.msgContent}")
            try {
                if (code == AirohaStatusCode.STATUS_SUCCESS) {
                    _equalizerState.value = _targetGains
                } else {
                    _targetGains = _equalizerState.value
                    Log.w(tag, "Equalizer settings not changed: $code.")
                }
            } catch (e: Exception) {
                _targetGains = _equalizerState.value
                Log.w(tag, "Equalizer settings error: ${e.message}.")
            }
        }
    }

    init {
        _airohaDeviceConnector.registerConnectionListener(_airohaConnectionListener)
        _devicePresenter = DeviceSearchPresenter(context)
    }

    fun destroy() {
        disconnectDevice()
        if (_budzServiceBound && _budzServiceConnection != null) {
            context.unbindService(_budzServiceConnection!!)
            _budzServiceBound = false
            _budzServiceConnection = null
        }
    }

    suspend fun connectDevice() {
        if (_deviceState.value != AirohaDeviceState.BONDED) {
            val bonded = isAirohaDeviceBonded()
            if (!bonded) {
                return
            }
        }
        connectAirohaDevice()
        deviceState.collect { deviceState ->
            if (deviceState == AirohaDeviceState.CONNECTED_AIROHA) {
                _deviceState.value = AirohaDeviceState.READY
            }
            if (deviceState == AirohaDeviceState.CONNECTED_AIROHA_WRONG_ROLE) {
                _deviceState.value = AirohaDeviceState.DISCONNECTED
            }
            if (deviceState == AirohaDeviceState.DISCONNECTED) {
                _deviceState.value = AirohaDeviceState.DISCONNECTED
            }
        }
    }

    fun disconnectDevice() {
        _devicePresenter?.destroy()
        val airohaDeviceConnector = AirohaSDK.getInst().airohaDeviceConnector
        airohaDeviceConnector.unregisterConnectionListener(_airohaConnectionListener)
    }

    fun startBleStreaming() = callbackFlow<Boolean> {
        connectServiceFlow().collect {serviceConnected ->
            if (serviceConnected) {
                _airohaBleManager?.connectFlow()?.collect {deviceState ->
                    if (deviceState == DeviceState.READY) {
                        _airohaBleManager?.startStreamingFlow()?.collect {streaming ->
                            if (streaming) {
                                startRaceBleStreamingFlow().collect { airohaStatusCode ->
                                    if (airohaStatusCode == AirohaStatusCode.STATUS_SUCCESS) {
                                        trySend(true)
                                    } else {
                                        trySend(false)
                                    }
                                }
                            } else {
                                trySend(false)
                            }
                        }
                    } else if (deviceState == DeviceState.DISCONNECTED) {
                        trySend(false)
                    }
                }
            } else {
                trySend(false)
            }
        }
    }

    fun stopBleStreamingFlow() = flow<Boolean> {
        if (!_budzServiceBound || _budzService == null) {
            emit(true)
            return@flow
        }
        stopRaceBleStreamingFlow().collect {airohaStatusCode ->
            if (airohaStatusCode == AirohaStatusCode.STATUS_SUCCESS) {
                _airohaBleManager?.disconnect()
                stopService()
                emit(true)
            } else {
                emit(false)
            }
        }
    }

    var _conn: ServiceConnection? = null

    private fun connectServiceFlow() = callbackFlow<Boolean> {
        val budzServiceConnection: ServiceConnection = object : ServiceConnection {
            override fun onServiceConnected(className: ComponentName, service: IBinder) {
                val binder: BudzService.LocalBinder = service as BudzService.LocalBinder
                _budzService = binder.service
                _airohaBleManager = _budzService?.getAirohaBleManager()
                _budzServiceBound = true
                RotatingFileLogger.get().logi(tag, "service bound.")
                trySend(true)
            }

            override fun onServiceDisconnected(componentName: ComponentName) {
                _budzServiceBound = false
                _budzService = null
                trySend(false)
            }
        }
        _conn = budzServiceConnection
        connectBudzService(budzServiceConnection)

        awaitClose {
            destroy()
        }

    }

    fun startRaceBleStreamingFlow() = callbackFlow<AirohaStatusCode> {
            val airohaDeviceListener = object : AirohaDeviceListener {
                override fun onRead(code: AirohaStatusCode, msg: AirohaBaseMsg) {
                    logAirohaResponse("onRead", code, msg)
                    trySend(code)
                }

                override fun onChanged(code: AirohaStatusCode, msg: AirohaBaseMsg) {
                    logAirohaResponse("onChanged", code, msg)
                    trySend(code)
                }
            }
            getAirohaDeviceControl().sendCustomCommand(
                getStartBleStreamingAirohaCommand(), airohaDeviceListener)
            awaitClose {}
        }

    fun stopRaceBleStreamingFlow() = callbackFlow<AirohaStatusCode> {
            val airohaDeviceListener = object : AirohaDeviceListener {
                override fun onRead(code: AirohaStatusCode, msg: AirohaBaseMsg) {
                    logAirohaResponse("onRead", code, msg)
                    trySend(code)
                }

                override fun onChanged(code: AirohaStatusCode, msg: AirohaBaseMsg) {
                    logAirohaResponse("onChanged", code, msg)
                    trySend(code)
                }
            }
            getAirohaDeviceControl().sendCustomCommand(
                getStopBleStreamingAirohaCommand(), airohaDeviceListener)
            awaitClose {}
        }

    private fun logAirohaResponse(method: String, code: AirohaStatusCode, msg: AirohaBaseMsg) {
        Log.d(tag, "$method: ${msg.msgContent}")
        if (code == AirohaStatusCode.STATUS_SUCCESS) {
            val resp = msg.msgContent as ByteArray
            Log.d(tag, "Read response: ${Converter.byte2HerStrReverse(resp)}")
        } else {
            Log.w(tag, "Read error: $code.")
        }
    }

    private fun getAirohaDeviceControl(): AirohaDeviceControl {
        return AirohaSDK.getInst().airohaDeviceControl
    }

    private fun getStartBleStreamingAirohaCommand(): AirohaCmdSettings {
        val raceCommand = AirohaCmdSettings()
        raceCommand.respType = RaceType.INDICATION
        raceCommand.command = DataStreamRaceCommand(
            DataStreamRaceCommand.DataStreamType.START_STREAM).getBytes()
        return raceCommand
    }

    private fun getStopBleStreamingAirohaCommand(): AirohaCmdSettings {
        val raceCommand = AirohaCmdSettings()
        raceCommand.respType = RaceType.INDICATION
        raceCommand.command = DataStreamRaceCommand(
            DataStreamRaceCommand.DataStreamType.STOP_STREAM).getBytes()
        return raceCommand
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

    private fun connectBudzService(serviceConnection: ServiceConnection) {
        _budzServiceIntent = Intent(context, BudzService::class.java)
        _budzServiceIntent!!.putExtra(
            BudzService.EXTRA_UI_CLASS,
            MainActivity::class.java
        )
        // Need to start the service explicitly so that 'onStartCommand' gets called in the service.
        context.startService(_budzServiceIntent)
        context.bindService(_budzServiceIntent!!, serviceConnection, Context.BIND_AUTO_CREATE)
    }

    private fun stopService() {
        if (_budzServiceIntent == null) {
            return
        }
        if (_budzServiceBound && _budzServiceConnection != null) {
            context.unbindService(_budzServiceConnection!!)
            _budzServiceBound = false
            _budzServiceConnection = null
        }
        context.stopService(_budzServiceIntent)
    }

    private fun isAirohaDeviceBonded(): Boolean {
        val bonded: Boolean = _devicePresenter?.findAirohaDevice() ?: false
        _deviceState.value = if (bonded) AirohaDeviceState.BONDED else
            AirohaDeviceState.DISCONNECTED
        return bonded
    }

    private fun connectAirohaDevice() {
        _devicePresenter?.connectBoundDevice()
    }

//    private val _budzServiceConnection: ServiceConnection = object : ServiceConnection {
//        override fun onServiceConnected(className: ComponentName, service: IBinder) {
//            val binder: BudzService.LocalBinder = service as BudzService.LocalBinder
//            _budzService = binder.service
//            _budzServiceBound = true
//            RotatingFileLogger.get().logi(tag, "service bound.")
//        }
//
//        override fun onServiceDisconnected(componentName: ComponentName) {
//            _budzServiceBound = false
//            _budzService = null
//        }
//    }
}