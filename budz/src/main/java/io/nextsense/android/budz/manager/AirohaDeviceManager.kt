package io.nextsense.android.budz.manager

import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.ServiceConnection
import android.os.IBinder
import com.airoha.libbase.RaceCommand.constant.RaceType
import com.airoha.libutils.Converter
import com.airoha.sdk.AirohaConnector
import com.airoha.sdk.AirohaSDK
import com.airoha.sdk.api.control.AirohaDeviceControl
import com.airoha.sdk.api.control.AirohaDeviceListener
import com.airoha.sdk.api.device.AirohaDevice
import com.airoha.sdk.api.message.AirohaBaseMsg
import com.airoha.sdk.api.message.AirohaBatteryInfo
import com.airoha.sdk.api.message.AirohaCmdSettings
import com.airoha.sdk.api.message.AirohaDeviceInfoMsg
import com.airoha.sdk.api.message.AirohaEQPayload
import com.airoha.sdk.api.utils.AirohaEQBandType
import com.airoha.sdk.api.utils.AirohaStatusCode
import dagger.hilt.android.qualifiers.ApplicationContext
import io.nextsense.android.airoha.device.AirohaBleManager
import io.nextsense.android.airoha.device.DataStreamRaceCommand
import io.nextsense.android.airoha.device.DeviceSearchPresenter
import io.nextsense.android.airoha.device.GetAfeRegisterRaceCommand
import io.nextsense.android.airoha.device.GetAfeRegisterRaceResponse
import io.nextsense.android.airoha.device.GetSoundLoopVolumeRaceCommand
import io.nextsense.android.airoha.device.PowerRaceCommand
import io.nextsense.android.airoha.device.RaceCommand
import io.nextsense.android.airoha.device.RaceResponseFactory
import io.nextsense.android.airoha.device.SetAfeRegisterRaceCommand
import io.nextsense.android.airoha.device.SetSoundLoopVolumeRaceCommand
import io.nextsense.android.airoha.device.SetTouchControlsRaceCommand
import io.nextsense.android.airoha.device.SetVoicePromptsControlsRaceCommand
import io.nextsense.android.airoha.device.SoundLoopControlsRaceCommand
import io.nextsense.android.airoha.device.SoundLoopVolumeRaceResponse
import io.nextsense.android.base.DeviceState
import io.nextsense.android.base.utils.RotatingFileLogger
import io.nextsense.android.budz.service.BudzService
import io.nextsense.android.budz.ui.activities.MainActivity
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.DelicateCoroutinesApi
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.last
import kotlinx.coroutines.flow.take
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeout
import java.util.LinkedList
import java.util.Timer
import java.util.TimerTask
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.coroutines.CoroutineContext
import kotlin.coroutines.EmptyCoroutineContext
import kotlin.math.ceil
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

enum class AirohaDeviceState {
    ERROR,  // Error when trying to connect to the device.
    DISCONNECTED,  // Device is not currently connected.
    BONDED,  // Device is bonded with Bluetooth Classic.
    CONNECTING_CLASSIC,  // Device is currently connecting.
    CONNECTED_AIROHA,  // Device is currently connected with Bluetooth Classic.
    READY  // Device is ready to use (Airoha connected, settings applied).
}

enum class BleDeviceState {
    ERROR,  // Error when trying to connect to the device.
    DISCONNECTED,  // Device is not currently connected.
    CONNECTING,  // Device is currently connecting.
    CONNECTED,  // Device is currently connected and ready.
    DISCONNECTING,  // Device is currently disconnecting.
}

enum class StreamingState {
    UNKNOWN, // Streaming state is unknown.
    STARTING,  // Starting streaming.
    STARTED,  // Streaming has started.
    STOPPING,  // Stopping streaming.
    STOPPED,  // Streaming has stopped.
    ERROR  // Error when trying to start or stop streaming.
}

data class AirohaBatteryLevel(
    val left: Int?,
    val right: Int?,
    val case: Int?
)

@Singleton
class AirohaDeviceManager @Inject constructor(
    @ApplicationContext private val context: Context,
    private val preferencesManager: PreferencesManager) {

    companion object {
        // Maximum value that can be set in the equalizer, either positive or negative.
        const val MAX_EQUALIZER_SETTING = 12
        // Frequencies that can be set in the equalizer.
        val EQ_FREQUENCIES =
            floatArrayOf(200f, 280f, 400f, 550f, 770f, 1000f, 2000f, 4000f, 8000f, 16000f)
        // Registers to set to put the device in DC impedance mode.
        val NO_IMPEDANCE_REGISTERS = mapOf(("BB" to "00003E"), ("D6" to "5900CD"))
        val DC_IMPEDANCE_REGISTERS = mapOf(("BB" to "00003F"), ("D6" to "5900CF"))
        const val DC_VALUE_REGISTER = "BC"
    }

    private val tag = AirohaDeviceManager::class.java.simpleName
    private val _airohaDeviceConnector = AirohaSDK.getInst().airohaDeviceConnector
    // Equalizer gains that are currently being set. _equalizerState is the current state, and will
    // get updated if these are set successfully.
    private val _airohaCommandInterval = 200.milliseconds
    private val _airohaDeviceState = MutableStateFlow(AirohaDeviceState.DISCONNECTED)
    private val _bleDeviceState = MutableStateFlow(BleDeviceState.DISCONNECTED)
    private val _streamingState = MutableStateFlow(StreamingState.UNKNOWN)
    private val _equalizerState = MutableStateFlow(FloatArray(10) { 0f })
    private val _scope = CoroutineScope(Dispatchers.IO)

    private var _airohaDeviceStateJob: Job? = null
    private var _budzServiceBound = false
    private var _budzServiceIntent: Intent? = null
    private var _budzService: BudzService? = null
    private var _budzServiceConnection: ServiceConnection? = null
    private var _airohaBleManager: AirohaBleManager? = null
    private var _devicePresenter: DeviceSearchPresenter? = null
    private var _twsConnected = MutableStateFlow(false)
    private var _deviceInfo: AirohaDevice? = null
    private var _targetGains: FloatArray = floatArrayOf(0f, 0f, 0f, 0f, 0f, 0f, 0f, 0f, 0f, 0f)
    private var _connectionTimeoutTimer: Timer? = null
    private var _forceStreaming = false
    private var _startStreamingJob: Job? = null
    private var _stopStreamingJob: Job? = null
    private var _connectBleJob: Job? = null
    private var _disconnectBleJob: Job? = null

    val airohaDeviceState: StateFlow<AirohaDeviceState> = _airohaDeviceState.asStateFlow()
    val bleDeviceState: StateFlow<BleDeviceState> = _bleDeviceState.asStateFlow()
    val streamingState: StateFlow<StreamingState> = _streamingState.asStateFlow()
    val equalizerState: StateFlow<FloatArray> = _equalizerState.asStateFlow()
    val twsConnected: StateFlow<Boolean?> = MutableStateFlow(null).asStateFlow()
    val deviceInfo: AirohaDevice? get() = _deviceInfo
    val isConnected: Boolean get() = _airohaDeviceState.value == AirohaDeviceState.CONNECTED_AIROHA ||
            isReady
    val isReady: Boolean get() = _airohaDeviceState.value == AirohaDeviceState.READY

    private val _airohaConnectionListener: AirohaConnector.AirohaConnectionListener =
        object: AirohaConnector.AirohaConnectionListener {
            override fun onStatusChanged(newStatus: Int) {
                when (newStatus) {
                    AirohaConnector.CONNECTED -> {
                        RotatingFileLogger.get().logd(tag, "Airoha connected.")
                        _airohaDeviceState.update { AirohaDeviceState.CONNECTED_AIROHA }
                    }
                    AirohaConnector.CONNECTED_WRONG_ROLE -> {
                        RotatingFileLogger.get().logw(tag,
                            "Airoha connected with wrong role. Disconnecting.")
                        disconnectDevice()
                    }
                    AirohaConnector.DISCONNECTED -> {
                        RotatingFileLogger.get().logd(tag, "Airoha disconnected.")
                        _airohaDeviceState.update { AirohaDeviceState.DISCONNECTED }
                        _scope.launch {
                            stopBleStreaming(overrideForceStreaming = true)
                        }
                    }
                    AirohaConnector.CONNECTING -> {
                        _airohaDeviceState.update { AirohaDeviceState.CONNECTING_CLASSIC }
                    }
                    AirohaConnector.CONNECTION_ERROR -> {
                        RotatingFileLogger.get().logw(tag, "Airoha connection error.")
                        _airohaDeviceState.update { AirohaDeviceState.ERROR }
                    }
                    AirohaConnector.INITIALIZATION_FAILED -> {
                        RotatingFileLogger.get().logw(tag, "Airoha initialization failed.")
                        _airohaDeviceState.update { AirohaDeviceState.ERROR }
                    }
                }
            }

            override fun onDataReceived(data: AirohaBaseMsg?) {
                // TODO(eric): Route to parse data based on message type
            }
        }

    private val airohaDeviceListener = object : AirohaDeviceListener {

        override fun onRead(code: AirohaStatusCode, msg: AirohaBaseMsg) {
            RotatingFileLogger.get().logd(tag, "Read response: ${msg.msgContent}")
            if (code == AirohaStatusCode.STATUS_SUCCESS) {
                val resp = msg.msgContent as ByteArray
                RotatingFileLogger.get().logd(tag,
                    "Read response: ${Converter.byteArrayToHexString(resp)}")
            } else {
                RotatingFileLogger.get().logw(tag, "Read error: $code.")
            }
        }

        override fun onChanged(code: AirohaStatusCode, msg: AirohaBaseMsg) {
            RotatingFileLogger.get().logd(tag, "Changed response: ${msg.msgContent}")
            try {
                if (code == AirohaStatusCode.STATUS_SUCCESS) {
                    _equalizerState.value = _targetGains
                } else {
                    _targetGains = _equalizerState.value
                    RotatingFileLogger.get().logw(tag, "Equalizer settings not changed: $code.")
                }
            } catch (e: Exception) {
                _targetGains = _equalizerState.value
                RotatingFileLogger.get().logw(tag, "Equalizer settings error: ${e.message}.")
            }
        }
    }

    fun BroadcastReceiver.goAsync(
        context: CoroutineContext = EmptyCoroutineContext,
        block: suspend CoroutineScope.() -> Unit
    ) {
        val pendingResult = goAsync()
        @OptIn(DelicateCoroutinesApi::class) // Must run globally; there's no teardown callback.
        GlobalScope.launch(context) {
            try {
                block()
            } finally {
                pendingResult.finish()
            }
        }
    }

    private val broadCastReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) = goAsync {
            when (intent.action) {
                BluetoothDevice.ACTION_ACL_CONNECTED -> {
                    RotatingFileLogger.get().logd(tag, "BluetoothDevice.ACTION_ACL_CONNECTED")
                    connectDevice(timeout = 30.seconds)
                }
            }
        }
    }

    init {
        initialize()
        _devicePresenter = DeviceSearchPresenter(context)
        RotatingFileLogger.get().logi(tag, "initialized")
    }

    fun initialize() {
        if (_airohaDeviceStateJob != null) {
            return
        }
        _scope.launch {
            connectServiceFlow().flowOn(Dispatchers.IO).first()
        }
        _airohaDeviceConnector.registerConnectionListener(_airohaConnectionListener)
        context.registerReceiver(broadCastReceiver,
            IntentFilter(BluetoothDevice.ACTION_ACL_CONNECTED))
        @OptIn(DelicateCoroutinesApi::class)
        _airohaDeviceStateJob = GlobalScope.launch {
            airohaDeviceState.collect { deviceState ->
                if (deviceState == AirohaDeviceState.CONNECTED_AIROHA) {
                    _connectionTimeoutTimer?.cancel()
                    _connectionTimeoutTimer = null
                    // Need to call these 2 APIs to correctly initialize the connection. If not,
                    // things like getting the battery levels do not work correctly.
                    // Also need a small delay between these commands or they often fail.
                    delay(_airohaCommandInterval)
                    _twsConnected.value = twsConnectStatusFlow().last() ?: false
                    RotatingFileLogger.get().logd(tag, "twsConnected=${_twsConnected.value}")
                    delay(_airohaCommandInterval)
                    _deviceInfo = deviceInfoFlow().last()
                    RotatingFileLogger.get().logd(tag, "deviceInfo=$_deviceInfo")
                    if (_deviceInfo == null) {
                        disconnectDevice()
                        _airohaDeviceState.value = AirohaDeviceState.ERROR
                        return@collect
                    }
                    delay(_airohaCommandInterval)
                    // TODO(eric): Probably use this setting later for real users.
                    val sleepMode = preferencesManager.prefs.getBoolean(
                            PreferenceKeys.SLEEP_MODE.name, false)
                    val voicePromptsDisabled = preferencesManager.prefs.getBoolean(
                            PreferenceKeys.VOICE_PROMPTS_DISABLED.name,
                        PreferenceKeys.VOICE_PROMPTS_DISABLED.getDefaultValue())
                    val touchControlsDisabled = preferencesManager.prefs.getBoolean(
                            PreferenceKeys.TOUCH_CONTROLS_DISABLED.name,
                        PreferenceKeys.TOUCH_CONTROLS_DISABLED.getDefaultValue())
                    setVoicePromptsEnabled(!voicePromptsDisabled)
                    setTouchControlsEnabled(!touchControlsDisabled)
                    _airohaDeviceState.value = AirohaDeviceState.READY
                    _scope.launch {
                        connectBle()
                    }
                }
            }
        }
    }

    suspend fun destroy() {
        setForceStream(false)
        _airohaDeviceStateJob?.cancel()
        _airohaDeviceStateJob = null
        try {
            context.unregisterReceiver(broadCastReceiver)
        } catch (e: Exception) {
            RotatingFileLogger.get().logw(tag,
                "Failed to unregister Bluetooth broadcast receiver: ${e.message}")
        }
        AirohaSDK.getInst().airohaDeviceConnector.unregisterConnectionListener(
            _airohaConnectionListener)
        _startStreamingJob?.cancel()
        _connectBleJob?.cancel()
        stopBleStreaming(true)
        disconnectBle()
        disconnectDevice()
        unbindService()
    }

    fun setForceStream(force: Boolean) {
        _forceStreaming = force
    }

    fun connectDevice(timeout: Duration? = null) {
        RotatingFileLogger.get().logi(tag, "connectDevice")
        if (_airohaDeviceState.value == AirohaDeviceState.READY ||
                _airohaDeviceState.value == AirohaDeviceState.CONNECTED_AIROHA) {
            RotatingFileLogger.get().logi(tag, "Device already connected.")
            return
        }
        if (_airohaDeviceState.value != AirohaDeviceState.BONDED) {
            isAirohaDeviceBonded()
        }
        _airohaDeviceState.value = AirohaDeviceState.CONNECTING_CLASSIC
        if (timeout != null) {
            _connectionTimeoutTimer = Timer()
            _connectionTimeoutTimer?.schedule(object : TimerTask() {
                override fun run() {
                    if (_airohaDeviceState.value == AirohaDeviceState.CONNECTING_CLASSIC) {
                        RotatingFileLogger.get().logi(tag,
                            "Timed out waiting for Airoha connection, disconnecting.")
                        disconnectDevice()
                        _airohaDeviceState.value = AirohaDeviceState.DISCONNECTED
                    }
                }
            }, timeout.inWholeMilliseconds)
        }
        connectAirohaDevice()
    }

    fun stopConnectingDevice() {
        RotatingFileLogger.get().logi(tag, "Stop trying to connect with Bluetooth classic.")
        _devicePresenter?.stopConnectingBoundDevice()
    }

    fun disconnectDevice() {
        _devicePresenter?.stopConnectingBoundDevice()
        _airohaDeviceState.value = AirohaDeviceState.DISCONNECTED
    }

    suspend fun connectBle() {
        if (_airohaDeviceState.value != AirohaDeviceState.READY) {
            return
        }

        if (!_budzServiceBound || _budzService == null) {
            RotatingFileLogger.get().logw(tag, "Tried to start streaming, but service is not " +
                    "available: $_budzServiceBound")
            return
        }

        _connectBleJob = _scope.launch {
            _bleDeviceState.value = BleDeviceState.CONNECTING
            val deviceMac = (_deviceInfo?.deviceMAC ?: "").filter { it != ':' }
            RotatingFileLogger.get().logd(tag, "Connecting to BLE devices with mac $deviceMac")
            val deviceState = _airohaBleManager?.connect(deviceMac, _twsConnected.value)
            if (deviceState == DeviceState.READY) {
                _bleDeviceState.value = BleDeviceState.CONNECTED
            } else if (deviceState == DeviceState.DISCONNECTED) {
                _bleDeviceState.value = BleDeviceState.DISCONNECTED
                return@launch
            }
        }
        _startStreamingJob?.join()
    }

    suspend fun disconnectBle() {
        _disconnectBleJob = _scope.launch {
            _bleDeviceState.value = BleDeviceState.DISCONNECTING
            _airohaBleManager?.disconnect()
            _bleDeviceState.value = BleDeviceState.DISCONNECTED
        }
        _disconnectBleJob?.join()
    }

    suspend fun startBleStreaming() {
        if (streamingState.value == StreamingState.STARTED) {
            return
        }

        if (streamingState.value == StreamingState.STOPPING) {
            // Wait until it finished stopping and give a small delay to make sure the firmware
            // is ready.
            try {
                withTimeout(5000L) {
                    streamingState.first {
                        it == StreamingState.STOPPED || it == StreamingState.ERROR
                    }
                }
                delay(500L)
            } catch (timeout: TimeoutCancellationException) {
                RotatingFileLogger.get().logi(tag,
                    "Timeout waiting for streaming to stop, starting again.")
            }
        }

        if (streamingState.value == StreamingState.STARTING) {
            return
            // Wait until it finished starting
//            try {
//                val result = streamingState.timeout(5.seconds).first {
//                    it == StreamingState.STARTED || it == StreamingState.ERROR
//                }
//                return result == StreamingState.STARTED
//            } catch (timeout: TimeoutCancellationException) {
//                RotatingFileLogger.get().logi(tag, "Timeout waiting for streaming to start, starting again.")
//            }
        }

        if (_airohaDeviceState.value != AirohaDeviceState.READY) {
            return
        }

        if (!_budzServiceBound || _budzService == null) {
            RotatingFileLogger.get().logw(tag, "Tried to start streaming, but service is not " +
                    "available: $_budzServiceBound")
            return
        }

        _startStreamingJob = _scope.launch {
            _streamingState.value = StreamingState.STARTING
            val readyForStreaming =
                _airohaBleManager!!.startStreaming(twsConnected.value ?: false)
            if (readyForStreaming) {
                // Clear the memory cache from the previous recording data, if any.
                _budzService?.memoryCache?.clear()
                val raceResponse = runSetRaceCommandFlow(getRaceCommand(
                    DataStreamRaceCommand(
                        DataStreamRaceCommand.DataStreamType.START_STREAM))).last()
                if (raceResponse != null && raceResponse.getStatusCode() ==
                        AirohaStatusCode.STATUS_SUCCESS) {
                    _streamingState.value = StreamingState.STARTED
                    return@launch
                }
                _streamingState.value = StreamingState.ERROR
                return@launch
            }
            _streamingState.value = StreamingState.ERROR
        }
        _startStreamingJob?.join()
    }

    suspend fun stopBleStreaming(overrideForceStreaming: Boolean = false) {
        if (_forceStreaming && !overrideForceStreaming) {
            return
        }
        if (overrideForceStreaming) {
            setForceStream(false)
        }
        if (_streamingState.value != StreamingState.STARTED &&
            _streamingState.value != StreamingState.STARTING) {
            if (_bleDeviceState.value == BleDeviceState.CONNECTING ||
                    _bleDeviceState.value == BleDeviceState.CONNECTED) {
                // Already stopped.
                _bleDeviceState.value = BleDeviceState.DISCONNECTED
            }
            return
        }

        if (streamingState.value == StreamingState.STOPPED) {
            return
        }

        if (streamingState.value == StreamingState.STOPPING) {
            // Wait until it finished stopping
            streamingState.take(1).last()
            return
        }

        if (streamingState.value == StreamingState.STARTING) {
            // Wait until it finished starting and then stop it.
            try {
                withTimeout(5000L) {
                    streamingState.first {
                        it == StreamingState.STARTED || it == StreamingState.ERROR
                    }
                }
            } catch (timeout: TimeoutCancellationException) {
                RotatingFileLogger.get().logi(tag,
                    "Timeout waiting for streaming to start, stopping anyway.")
            }
            delay(500L)
        }

        _stopStreamingJob = _scope.launch {
            _streamingState.value = StreamingState.STOPPING
            if (_airohaDeviceState.value == AirohaDeviceState.CONNECTED_AIROHA ||
                _airohaDeviceState.value == AirohaDeviceState.READY) {
                val raceResponse = runSetRaceCommandFlow(getRaceCommand(
                    DataStreamRaceCommand(DataStreamRaceCommand.DataStreamType.STOP_STREAM)))
                    .take(1).last()
                if (raceResponse != null && raceResponse.getStatusCode() ==
                        AirohaStatusCode.STATUS_SUCCESS) {
                    _streamingState.value = StreamingState.ERROR
                    return@launch
                }
            }
            _airohaBleManager?.stopStreaming()
            _streamingState.value = StreamingState.STOPPED
        }
        _stopStreamingJob?.join()
    }

    fun runSleepWakeInference(data: List<Float>) : Boolean? {
        if (!_budzServiceBound || _budzService == null) {
            return null
        }
        return _budzService?.sleepWakeModel?.doInference(data, getEegSamplingRate())
    }

    fun startSoundLoop() {
        if (!isConnected) {
            RotatingFileLogger.get().logw(tag, "Tried to start sound loop, but device is not " +
                    "available: ${_airohaDeviceState.value}")
            return
        }
        getAirohaDeviceControl().sendCustomCommand(
            getRaceCommand(
                SoundLoopControlsRaceCommand(
                soundLoopType = SoundLoopControlsRaceCommand.SoundLoopType.START_LOOP,
                soundLoopId = 0, mixSounds = true, mixLengthSeconds = 5)),
            airohaDeviceListener
        )
    }

    fun stopSoundLoop() {
        if (!isConnected) {
            RotatingFileLogger.get().logw(tag, "Tried to start sound loop, but device is not " +
                    "available: ${_airohaDeviceState.value}")
            return
        }
        getAirohaDeviceControl().sendCustomCommand(
            getRaceCommand(
                SoundLoopControlsRaceCommand(
                    soundLoopType = SoundLoopControlsRaceCommand.SoundLoopType.STOP_LOOP,
                    soundLoopId = 0, mixSounds = true, mixLengthSeconds = 5)),
            airohaDeviceListener
        )
    }

    fun reset() {
        if (!isConnected) {
            RotatingFileLogger.get().logw(tag, "Tried to reset device, but device is not " +
                    "available: ${_airohaDeviceState.value}")
            return
        }
        getAirohaDeviceControl().sendCustomCommand(
            getRaceCommand(PowerRaceCommand(PowerRaceCommand.PowerType.RESET)),
            airohaDeviceListener
        )
    }

    fun powerOff() {
        if (!isConnected) {
            RotatingFileLogger.get().logw(tag, "Tried to power off device, but device is not " +
                    "available: ${_airohaDeviceState.value}")
            return
        }
        getAirohaDeviceControl().sendCustomCommand(
            getRaceCommand(PowerRaceCommand(PowerRaceCommand.PowerType.POWER_OFF)),
            airohaDeviceListener
        )
    }

    suspend fun setAfeRegisterValue(channel: EarEegChannel, register: String, value: String):
            AirohaStatusCode? {
        if (!isConnected) {
            RotatingFileLogger.get().logw(tag, "Tried to set AFE register, but device is not" +
                    " available: ${_airohaDeviceState.value}")
            return null
        }
        if (register.length != 2 || value.length != 6) {
            RotatingFileLogger.get().logw(tag, "Invalid register or value: $register, $value")
            return null
        }

        val earBudSide = when (channel) {
            EarEegChannel.ELW_ELC -> SetAfeRegisterRaceCommand.EarbudSide.LEFT
            EarEegChannel.ERW_ERC -> SetAfeRegisterRaceCommand.EarbudSide.RIGHT
            else -> SetAfeRegisterRaceCommand.EarbudSide.LEFT
        }
        val raceResponse = runSetRaceCommandFlow(getRaceCommand(SetAfeRegisterRaceCommand(
            earBudSide, register, value))).first()
        return raceResponse?.getStatusCode()
    }

    suspend fun getAfeRegisterValue(channel: EarEegChannel, register: String): ByteArray? {
        if (!isConnected) {
            RotatingFileLogger.get().logw(tag, "Tried to get AFE register, but device is not " +
                    "available: ${_airohaDeviceState.value}")
            return null
        }
        val earBudSide = when (channel) {
            EarEegChannel.ELW_ELC -> SetAfeRegisterRaceCommand.EarbudSide.LEFT
            EarEegChannel.ERW_ERC -> SetAfeRegisterRaceCommand.EarbudSide.RIGHT
            else -> SetAfeRegisterRaceCommand.EarbudSide.LEFT
        }
        val afeRaceResponse = getRaceCommandResponseFlow(getRaceCommand(
            GetAfeRegisterRaceCommand(earBudSide, register))).first() as GetAfeRegisterRaceResponse?
        if (afeRaceResponse == null ||
            afeRaceResponse.getStatusCode() != AirohaStatusCode.STATUS_SUCCESS) {
            RotatingFileLogger.get().logw(tag, "Failed to get AFE register. Reason: " +
                    "${afeRaceResponse?.getStatusCode()}")
            return null
        }
        return afeRaceResponse.getValue()
    }

    suspend fun setSoundLoopVolume(volume: Int): AirohaStatusCode? {
        if (!isConnected) {
            RotatingFileLogger.get().logw(tag, "Tried to set sound loop volume, but device is " +
                    "not available: ${_airohaDeviceState.value}")
            return null
        }

        val raceResponse = runSetRaceCommandFlow(
            getRaceCommand(SetSoundLoopVolumeRaceCommand(volume))).first()
        return raceResponse?.getStatusCode()
    }

    suspend fun getSoundLoopVolume(): Int? {
        if (!isConnected) {
            RotatingFileLogger.get().logw(tag, "Tried to get sound loop volume, but device is " +
                    "not available: ${_airohaDeviceState.value}")
            return null
        }
        val soundLoopVolumeResponse = getRaceCommandResponseFlow(getRaceCommand(
            GetSoundLoopVolumeRaceCommand())).first() as SoundLoopVolumeRaceResponse?
        if (soundLoopVolumeResponse == null ||
            soundLoopVolumeResponse.getStatusCode() != AirohaStatusCode.STATUS_SUCCESS) {
            RotatingFileLogger.get().logw(tag, "Failed to get sound loop volume. Reason: " +
                    "${soundLoopVolumeResponse?.getStatusCode()}")
            return null
        }
        return soundLoopVolumeResponse.getVolume()
    }

    suspend fun setTouchControlsEnabled(enabled: Boolean): AirohaStatusCode? {
        if (!isConnected) {
            RotatingFileLogger.get().logw(tag, "Tried to set touch controls, but device is " +
                    "not available: ${_airohaDeviceState.value}")
            return null
        }

        val raceResponse = runSetRaceCommandFlow(getRaceCommand(
            SetTouchControlsRaceCommand(disable=!enabled))).first()
        return raceResponse?.getStatusCode()
    }

    suspend fun setVoicePromptsEnabled(enabled: Boolean): AirohaStatusCode? {
        if (!isConnected) {
            RotatingFileLogger.get().logw(tag, "Tried to set voice prompts, but device is " +
                    "not available: ${_airohaDeviceState.value}")
            return null
        }

        val raceResponse = runSetRaceCommandFlow(getRaceCommand(
            SetVoicePromptsControlsRaceCommand(disable=!enabled))).first()
        return raceResponse?.getStatusCode()
    }

    suspend fun setRegisters(registers: Map<String, String>): AirohaStatusCode? {
        if (!isConnected) {
            RotatingFileLogger.get().logw(
                tag, "Tried to set registers, but device is " +
                        "not available: ${_airohaDeviceState.value}"
            )
            return null
        }

        var statusCode: AirohaStatusCode? = null
        for ((register, value) in registers) {
            for (earbudChannel in EarbudsConfigs.getEarbudsConfig(
                    EarbudsConfigNames.MAUI_CONFIG.name).channelsConfig.values) {
                statusCode = setAfeRegisterValue(earbudChannel, register, value)
                if (statusCode != AirohaStatusCode.STATUS_SUCCESS) {
                    break
                }
            }
        }
        return statusCode
    }

    suspend fun switchDCImpedanceMode(enabled: Boolean) : AirohaStatusCode? {
        if (!isConnected) {
            RotatingFileLogger.get().logw(tag, "Tried to switch DC impedance mode, but device is " +
                    "not available: ${_airohaDeviceState.value}")
            return null
        }

        if (enabled) {
            return setRegisters(DC_IMPEDANCE_REGISTERS)
        }
        return setRegisters(NO_IMPEDANCE_REGISTERS)
    }

    suspend fun getDCValue(earEegChannel: EarEegChannel) : ByteArray? {
        if (!isConnected) {
            RotatingFileLogger.get().logw(tag, "Tried to get DC value, but device is " +
                    "not available: ${_airohaDeviceState.value}")
            return null
        }
        return getAfeRegisterValue(earEegChannel, DC_VALUE_REGISTER)
    }

    fun changeEqualizer(gains: FloatArray) : Boolean {
        if (_airohaDeviceState.value != AirohaDeviceState.READY) {
            return false
        }
        _targetGains = gains
        val params = LinkedList<AirohaEQPayload.EQIDParam>()
        for (i in EQ_FREQUENCIES.indices) {
            val bandInfo = AirohaEQPayload.EQIDParam()
            val freq: Float = EQ_FREQUENCIES[i]
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
        return true
    }

    fun batteryLevelsFlow() = callbackFlow<AirohaBatteryLevel> {
        val batteryInfoListener = object : AirohaDeviceListener {
            override fun onRead(code: AirohaStatusCode, msg: AirohaBaseMsg?) {
                RotatingFileLogger.get().logd(tag,"BatteryInfoListener.onRead=" +
                        "${code.description}, msg = ${msg?.msgID?.cmdName}")

                var leftBattery: Int? = null
                var rightBattery: Int? = null
                var caseBattery: Int? = null

                try {
                    if (code == AirohaStatusCode.STATUS_SUCCESS && msg != null) {
                        val batteryInfo = msg.msgContent as AirohaBatteryInfo

                        RotatingFileLogger.get().logd(tag,
                            "batteryInfo master level ${batteryInfo.masterLevel}")
                        RotatingFileLogger.get().logd(tag,
                            "batteryInfo slave level ${batteryInfo.slaveLevel}")
                        RotatingFileLogger.get().logd(tag,
                            "AirohaSDK.getInst().isAgentRightSideDevice()=" +
                                "${AirohaSDK.getInst().isAgentRightSideDevice}")
                        if (AirohaSDK.getInst().isAgentRightSideDevice) {
                            rightBattery = batteryInfo.masterLevel
                            leftBattery = batteryInfo.slaveLevel
                            caseBattery = batteryInfo.boxLevel
                        } else {
                            leftBattery = batteryInfo.masterLevel
                            rightBattery = batteryInfo.slaveLevel
                            caseBattery = batteryInfo.boxLevel
                        }
                    }
                } catch (e: java.lang.Exception) {
                    RotatingFileLogger.get().loge(tag, e.message)
                }
                trySend(AirohaBatteryLevel(leftBattery, rightBattery, caseBattery))
                channel.close()
            }

            override fun onChanged(code: AirohaStatusCode, msg: AirohaBaseMsg) {
                // Nothing to do.
            }
        }

        AirohaSDK.getInst().airohaDeviceControl.getBatteryInfo(batteryInfoListener)

        awaitClose {
        }
    }

    private fun runSetRaceCommandFlow(raceCommand: AirohaCmdSettings) =
        callbackFlow {
            val airohaDeviceListener = object : AirohaDeviceListener {
                override fun onRead(code: AirohaStatusCode, msg: AirohaBaseMsg) {
                    logAirohaResponse("onRead", code, msg)
                    val raceResponse = RaceResponseFactory.create(msg.msgContent as ByteArray)
                    trySend(raceResponse)
                    channel.close()
                }

                override fun onChanged(code: AirohaStatusCode, msg: AirohaBaseMsg) {
                    logAirohaResponse("onChanged", code, msg)
                    val raceResponse = RaceResponseFactory.create(msg.msgContent as ByteArray)
                    trySend(raceResponse)
                    channel.close()
                }
            }

            getAirohaDeviceControl().sendCustomCommand(raceCommand, airohaDeviceListener)

            awaitClose {
            }
        }

    private fun getRaceCommandResponseFlow(raceCommand: AirohaCmdSettings) =
        callbackFlow {
            val airohaDeviceListener = object : AirohaDeviceListener {
                override fun onRead(code: AirohaStatusCode, msg: AirohaBaseMsg) {
                    logAirohaResponse("onRead", code, msg)
                    val raceResponse = RaceResponseFactory.create(msg.msgContent as ByteArray)
                    trySend(raceResponse)
                    channel.close()
                }

                override fun onChanged(code: AirohaStatusCode, msg: AirohaBaseMsg) {
                    logAirohaResponse("onChanged", code, msg)
                    val raceResponse = RaceResponseFactory.create(msg.msgContent as ByteArray)
                    trySend(raceResponse)
                    channel.close()
                }
            }

            getAirohaDeviceControl().sendCustomCommand(raceCommand, airohaDeviceListener)

            awaitClose {
            }
        }

    fun getEegSamplingRate() : Float {
        return _airohaBleManager?.getEegSamplingRate() ?: 1000f
    }

    fun getChannelData(
        localSessionId: Int?,
        channelName: String,
        durationMillis: Int,
        fromDatabase: Boolean?
    ) : List<Float>? {
        if (fromDatabase != null && fromDatabase) {
            var selectedLocalSessionId: Int? = localSessionId
            if (localSessionId == null) {
                selectedLocalSessionId =
                    _budzService?.localSessionManager?.activeLocalSession?.get()?.id?.toInt()
                if (selectedLocalSessionId == null) {
                    return null
                }
            }
            return _budzService?.getObjectBoxDatabase()?.getLastChannelData(
                selectedLocalSessionId!!,
                channelName,
                java.time.Duration.ofMillis(durationMillis.toLong())
            )
        }
        val eegSamplingRate = getEegSamplingRate()
        val numberOfSamples = Math.round(
            ceil(
                (durationMillis.toFloat() / Math.round(
                    1000f / eegSamplingRate
                )).toDouble()
            )
        ).toInt()
        return _budzService?.getMemoryCache()?.getLastEegChannelData(
            channelName, numberOfSamples)
    }

    private fun twsConnectStatusFlow() = callbackFlow<Boolean?> {
        val twsConnectStatusListener = object : AirohaDeviceListener {
                override fun onRead(code: AirohaStatusCode, msg: AirohaBaseMsg) {
                    RotatingFileLogger.get().logd(tag, "TwsConnectStatusListener.onRead=" +
                            "${code.description}, msg = ${msg.msgID.cmdName}")
                    try {
                        if (code == AirohaStatusCode.STATUS_SUCCESS) {
                            val isTwsConnected = msg.msgContent as Boolean
                            RotatingFileLogger.get().logd(tag, "isTwsConnected=$isTwsConnected")
                            trySend(isTwsConnected)
                        } else {
                            RotatingFileLogger.get().logd(tag, "getTwsConnectStatus: " +
                                    "${code.description}, msg = ${msg.msgID.cmdName}")
                            trySend(null)
                        }
                    } catch (e: java.lang.Exception) {
                        RotatingFileLogger.get().loge(tag, e.message)
                        trySend(null)
                    }
                    channel.close()
                }

                override fun onChanged(code: AirohaStatusCode, msg: AirohaBaseMsg) {
                    // Nothing to do.
                }
            }

        AirohaSDK.getInst().airohaDeviceControl.getTwsConnectStatus(twsConnectStatusListener)

        awaitClose {
        }
    }

    @Suppress("UNCHECKED_CAST")
    private fun deviceInfoFlow() = callbackFlow<AirohaDevice?> {
        val deviceInfoListener = object : AirohaDeviceListener {
            override fun onRead(code: AirohaStatusCode, msg: AirohaBaseMsg) {
                RotatingFileLogger.get().logd(tag, "DeviceInfoListener.onRead=" +
                        "${code.description}, msg = ${msg.msgID.cmdName}")
                try {
                    if (code == AirohaStatusCode.STATUS_SUCCESS) {
                        RotatingFileLogger.get().logd(tag, "Parsing DeviceInfo")
                        val deviceInfoMessage = msg as AirohaDeviceInfoMsg
                        val content = deviceInfoMessage.msgContent as LinkedList<AirohaDevice>
                        if (content.isEmpty()) {
                            trySend(null)
                            channel.close()
                            return
                        }
                        val airohaDevice = content[0]
                        if (AirohaSDK.getInst().isPartnerExisting) {
                            val airohaDevicePartner = content[1]
                            if (airohaDevicePartner.deviceName != null &&
                                airohaDevicePartner.deviceName.isNotEmpty()
                            ) {
                                airohaDevice.deviceName = airohaDevicePartner.deviceName
                            }
                        }
                        trySend(airohaDevice)
                    } else {
                        trySend(null)
                    }
                } catch (e: java.lang.Exception) {
                    RotatingFileLogger.get().loge(tag, e.message)
                    trySend(null)
                }
                channel.close()
            }

            override fun onChanged(code: AirohaStatusCode, msg: AirohaBaseMsg) {
                // Nothing to do.
            }
        }

        AirohaSDK.getInst().airohaDeviceControl.getDeviceInfo(deviceInfoListener)

        awaitClose {
        }
    }

    private fun logAirohaResponse(method: String, code: AirohaStatusCode, msg: AirohaBaseMsg) {
        RotatingFileLogger.get().logd(tag, "$method: ${msg.msgContent}")
        if (code == AirohaStatusCode.STATUS_SUCCESS) {
            val resp = msg.msgContent as ByteArray
            RotatingFileLogger.get().logd(tag, "Read response: " +
                    Converter.byteArrayToHexString(resp)
            )
        } else {
            RotatingFileLogger.get().logw(tag, "Read error: $code.")
        }
    }

    private fun getAirohaDeviceControl(): AirohaDeviceControl {
        return AirohaSDK.getInst().airohaDeviceControl
    }

    private fun getRaceCommand(command: RaceCommand, raceType: Byte = RaceType.INDICATION):
            AirohaCmdSettings {
        val raceCommand = AirohaCmdSettings()
        raceCommand.respType = raceType
        raceCommand.command = command.getBytes()
        RotatingFileLogger.get().logd(
            tag, "${command.getName()}: ${Converter.byteArrayToHexString(raceCommand.command)}")
        return raceCommand
    }

    private fun connectServiceFlow() = callbackFlow<Boolean> {
        val budzServiceConnection: ServiceConnection = object : ServiceConnection {
            override fun onServiceConnected(className: ComponentName, service: IBinder) {
                val binder: BudzService.LocalBinder = service as BudzService.LocalBinder
                _budzService = binder.service
                _airohaBleManager = _budzService?.airohaBleManager
                _budzServiceBound = true
                RotatingFileLogger.get().logi(tag, "service bound.")
                trySend(true)
            }

            override fun onServiceDisconnected(componentName: ComponentName) {
                _budzServiceConnection = null
                _budzService = null
                _budzServiceBound = false
                trySend(false)
            }
        }

        _budzServiceConnection = budzServiceConnection
        connectBudzService(budzServiceConnection)

        awaitClose {
            // destroy()
        }
    }

    private fun connectBudzService(serviceConnection: ServiceConnection) {
        _budzServiceIntent = Intent(context, BudzService::class.java)
        _budzServiceIntent!!.putExtra(
            BudzService.EXTRA_UI_CLASS,
            MainActivity::class.java
        )
        context.bindService(_budzServiceIntent!!, serviceConnection, Context.BIND_IMPORTANT)
    }

    private fun unbindService() {
        if (_budzServiceIntent == null) {
            return
        }
        if (_budzServiceBound && _budzServiceConnection != null) {
            try {
                context.unbindService(_budzServiceConnection!!)
            } catch (e: IllegalArgumentException) {
                RotatingFileLogger.get().logw(tag, e.message)
            } finally {
                _budzServiceBound = false
                _budzServiceConnection = null
            }
       }
        _budzService = null
    }

    private fun isAirohaDeviceBonded(): Boolean {
        val bonded: Boolean = _devicePresenter?.findAirohaDevice() ?: false
        _airohaDeviceState.value = if (bonded) AirohaDeviceState.BONDED else
            AirohaDeviceState.DISCONNECTED
        RotatingFileLogger.get().logi(tag, "isAirohaDeviceBonded=$bonded")
        return bonded
    }

    private fun connectAirohaDevice() {
        val alreadyConnected: Boolean = _devicePresenter?.connectBoundDevice() ?: false
        if (alreadyConnected) {
            _airohaDeviceState.value = AirohaDeviceState.CONNECTED_AIROHA
        }
    }
}