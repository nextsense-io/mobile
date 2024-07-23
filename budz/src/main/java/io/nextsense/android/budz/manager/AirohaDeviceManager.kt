package io.nextsense.android.budz.manager

import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.ServiceConnection
import android.os.IBinder
import android.util.Log
import androidx.localbroadcastmanager.content.LocalBroadcastManager
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
import io.nextsense.android.airoha.device.StartStopSoundLoopRaceCommand
import io.nextsense.android.base.DeviceState
import io.nextsense.android.base.utils.RotatingFileLogger
import io.nextsense.android.budz.service.BudzService
import io.nextsense.android.budz.ui.activities.MainActivity
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.DelicateCoroutinesApi
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.callbackFlow
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
import kotlin.time.Duration.Companion.seconds

enum class AirohaDeviceState {
    ERROR,  // Error when trying to connect to the device.
    DISCONNECTED,  // Device is not currently connected.
    BONDED,  // Device is bonded with Bluetooth Classic.
    CONNECTING_CLASSIC,  // Device is currently connecting.
    CONNECTED_AIROHA,  // Device is currently connected with Bluetooth Classic.
    CONNECTING_BLE,  // Device is currently connecting with BLE.
    CONNECTED_BLE,  // Device is currently connected with BLE and Bluetooth Classic.
    READY  // Device is ready to use (Airoha and BLE connected, settings applied).
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
class AirohaDeviceManager @Inject constructor(@ApplicationContext private val context: Context) {

    private val tag = AirohaDeviceManager::class.java.simpleName
    private val _airohaDeviceConnector = AirohaSDK.getInst().airohaDeviceConnector
    // Frequencies that can be set in the equalizer.
    private val _eqFrequencies =
        floatArrayOf(200f, 280f, 400f, 550f, 770f, 1000f, 2000f, 4000f, 8000f, 16000f)
    // Equalizer gains that are currently being set. _equalizerState is the current state, and will
    // get updated if these are set successfully.
    private val _airohaDeviceState = MutableStateFlow(AirohaDeviceState.DISCONNECTED)
    private val _streamingState = MutableStateFlow(StreamingState.UNKNOWN)
    private val _equalizerState = MutableStateFlow(FloatArray(10) { 0f })

    private var _budzServiceBound = false
    private var _budzServiceIntent: Intent? = null
    private var _budzService: BudzService? = null
    private var _budzServiceConnection: ServiceConnection? = null
    private var _airohaBleManager: AirohaBleManager? = null
    private var _devicePresenter: DeviceSearchPresenter? = null
    private var _twsConnected: Boolean? = null
    private var _deviceInfo: AirohaDevice? = null
    private var _targetGains: FloatArray = floatArrayOf(0f,0f,0f,0f,0f,0f,0f,0f,0f,0f)
    private var _connectionTimeoutTimer: Timer? = null

    val airohaDeviceState: StateFlow<AirohaDeviceState> = _airohaDeviceState.asStateFlow()
    val streamingState: StateFlow<StreamingState> = _streamingState.asStateFlow()
    val equalizerState: StateFlow<FloatArray> = _equalizerState.asStateFlow()

    private val _airohaConnectionListener: AirohaConnector.AirohaConnectionListener =
        object: AirohaConnector.AirohaConnectionListener {
            override fun onStatusChanged(newStatus: Int) {
                when (newStatus) {
                    AirohaConnector.CONNECTED -> {
                        Log.d(tag, "Airoha connected.")
                        _airohaDeviceState.update { AirohaDeviceState.CONNECTED_AIROHA }
                    }
                    AirohaConnector.CONNECTED_WRONG_ROLE -> {
                        Log.w(tag, "Airoha connected with wrong role. Disconnecting.")
                        disconnectDevice()
                    }
                    AirohaConnector.DISCONNECTED -> {
                        Log.d(tag, "Airoha disconnected.")
                        _airohaDeviceState.update { AirohaDeviceState.DISCONNECTED }
                    }
                    AirohaConnector.CONNECTING -> {
                        _airohaDeviceState.update { AirohaDeviceState.CONNECTING_CLASSIC }
                    }
                    AirohaConnector.CONNECTION_ERROR -> {
                        Log.w(tag, "Airoha connection error.")
                        _airohaDeviceState.update { AirohaDeviceState.ERROR }
                    }
                    AirohaConnector.INITIALIZATION_FAILED -> {
                        Log.w(tag, "Airoha initialization failed.")
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
                    Log.d(tag, "BluetoothDevice.ACTION_ACL_CONNECTED")
                    connectDevice(timeout = 30.seconds)
                }
            }
        }
    }

    init {
        _airohaDeviceConnector.registerConnectionListener(_airohaConnectionListener)
        _devicePresenter = DeviceSearchPresenter(context)
        context.registerReceiver(broadCastReceiver, IntentFilter(BluetoothDevice.ACTION_ACL_CONNECTED))

        @OptIn(DelicateCoroutinesApi::class)
        GlobalScope.launch {
            airohaDeviceState.collect { deviceState ->
                if (deviceState == AirohaDeviceState.CONNECTED_AIROHA) {
                    _connectionTimeoutTimer?.cancel()
                    _connectionTimeoutTimer = null
                    // Need to call these 2 APIs to correctly initialize the connection. If not, things
                    // like getting the battery levels do not work correctly.
                    // Also need a small delay between these commands or they often fail.
                    delay(200L)
                    _twsConnected = twsConnectStatusFlow().last()
                    Log.d(tag, "twsConnected=$_twsConnected")
                    delay(200L)
                    _deviceInfo = deviceInfoFlow().last()
                    Log.d(tag, "deviceInfo=$_deviceInfo")
                    if (_twsConnected == null || _deviceInfo == null) {
                        disconnectDevice()
                        _airohaDeviceState.value = AirohaDeviceState.ERROR
                        return@collect
                    }
                    _airohaDeviceState.value = AirohaDeviceState.READY
                }
            }
        }
        Log.i(tag, "initialized")
    }

    fun destroy() {
        LocalBroadcastManager.getInstance(context).unregisterReceiver(broadCastReceiver)
        disconnectDevice()
        if (_budzServiceBound && _budzServiceConnection != null) {
            context.unbindService(_budzServiceConnection!!)
            _budzServiceBound = false
            _budzServiceConnection = null
        }
    }

    fun connectDevice(timeout: Duration? = null) {
        Log.i(tag, "connectDevice")
        if (_airohaDeviceState.value == AirohaDeviceState.READY ||
                _airohaDeviceState.value == AirohaDeviceState.CONNECTED_BLE ||
                _airohaDeviceState.value == AirohaDeviceState.CONNECTED_AIROHA ||
                _airohaDeviceState.value == AirohaDeviceState.CONNECTING_BLE) {
            Log.i(tag, "Device already connected.")
            return
        }
        _airohaDeviceState.value = AirohaDeviceState.CONNECTING_CLASSIC
        if (_airohaDeviceState.value != AirohaDeviceState.BONDED) {
            isAirohaDeviceBonded()
        }
        if (timeout != null) {
            _connectionTimeoutTimer = Timer()
            _connectionTimeoutTimer?.schedule(object : TimerTask() {
                override fun run() {
                    if (_airohaDeviceState.value == AirohaDeviceState.CONNECTING_CLASSIC) {
                        Log.i(tag, "Timed out waiting for Airoha connection, disconnecting.")
                        disconnectDevice()
                        _airohaDeviceState.value = AirohaDeviceState.DISCONNECTED
                    }
                }
            }, timeout.inWholeMilliseconds)
        }
        connectAirohaDevice()
    }

    fun stopConnectingDevice() {
        _devicePresenter?.stopConnectingBoundDevice()
    }

    fun disconnectDevice() {
        _devicePresenter?.stopConnectingBoundDevice()
        val airohaDeviceConnector = AirohaSDK.getInst().airohaDeviceConnector
        airohaDeviceConnector.unregisterConnectionListener(_airohaConnectionListener)
        _airohaDeviceState.value = AirohaDeviceState.DISCONNECTED
    }

    suspend fun startBleStreaming() : Boolean {
        if (_airohaDeviceState.value != AirohaDeviceState.READY) {
            return false
        }

        if (streamingState.value == StreamingState.STARTED) {
            return true
        }

        if (streamingState.value == StreamingState.STARTING) {
            // Wait until it finished starting
            val result = streamingState.take(1).last()
            return result == StreamingState.STARTED
        }

        if (streamingState.value == StreamingState.STOPPING) {
            // Wait until it finished stopping and give a small delay to make sure the firmware
            // is ready.
            streamingState.take(1).last()
            delay(500L)
        }

        _streamingState.value = StreamingState.STARTING
        _airohaDeviceState.value = AirohaDeviceState.CONNECTING_BLE
        val serviceConnected = withTimeout(2000L) {
            connectServiceFlow().flowOn(Dispatchers.IO).take(1).last()
        }
        if (serviceConnected) {
            val deviceState =_airohaBleManager?.connect()
            if (deviceState == DeviceState.READY) {
                _airohaDeviceState.value = AirohaDeviceState.CONNECTED_BLE
                val readyForStreaming = _airohaBleManager!!.startStreaming()
                if (readyForStreaming) {
                    // Clear the memory cache from the previous recording data, if any.
                    _budzService?.getMemoryCache()?.clear()
                    val airohaStatusCode = startRaceBleStreamingFlow().last()
                    if (airohaStatusCode == AirohaStatusCode.STATUS_SUCCESS) {
                        _streamingState.value = StreamingState.STARTED
                        return true
                    } else {
                        _streamingState.value = StreamingState.ERROR
                        return false
                    }
                } else {
                    _streamingState.value = StreamingState.ERROR
                    return false
                }
            } else if (deviceState == DeviceState.DISCONNECTED) {
                _airohaDeviceState.value = AirohaDeviceState.READY
                _streamingState.value = StreamingState.STOPPED
                return false
            }
        } else {
            _airohaDeviceState.value = AirohaDeviceState.READY
            _streamingState.value = StreamingState.STOPPED
            return false
        }
        return false
    }

    suspend fun stopBleStreaming() : Boolean {
        if (!_budzServiceBound || _budzService == null ||
                _streamingState.value != StreamingState.STARTED) {
            if (_airohaDeviceState.value == AirohaDeviceState.CONNECTING_BLE ||
                    _airohaDeviceState.value == AirohaDeviceState.CONNECTED_BLE) {
                // Already stopped.
                _airohaDeviceState.value = AirohaDeviceState.READY
            }
            return true
        }

        if (streamingState.value == StreamingState.STOPPED) {
            return true
        }

        if (streamingState.value == StreamingState.STOPPING) {
            // Wait until it finished stopping
            val result = streamingState.take(1).last()
            return result == StreamingState.STOPPED
        }

        if (streamingState.value == StreamingState.STARTING) {
            // Wait until it finished starting and then stop it.
            streamingState.take(1).last()
            delay(500L)
        }

        _streamingState.value = StreamingState.STOPPING
        val airohaStatusCode = stopRaceBleStreamingFlow().take(1).last()
        if (airohaStatusCode == AirohaStatusCode.STATUS_SUCCESS) {
            _airohaBleManager?.stopStreaming()
            _airohaBleManager?.disconnect()
            _airohaDeviceState.value = AirohaDeviceState.READY
            _streamingState.value = StreamingState.STOPPED
            stopService()
            return true
        } else {
            _streamingState.value = StreamingState.ERROR
            return false
        }
    }

    fun startRaceBleStreamingFlow() = callbackFlow<AirohaStatusCode> {
        val airohaDeviceListener = object : AirohaDeviceListener {
            override fun onRead(code: AirohaStatusCode, msg: AirohaBaseMsg) {
                logAirohaResponse("onRead", code, msg)
                trySend(code)
                channel.close()
            }

            override fun onChanged(code: AirohaStatusCode, msg: AirohaBaseMsg) {
                logAirohaResponse("onChanged", code, msg)
                trySend(code)
                channel.close()
            }
        }

        getAirohaDeviceControl().sendCustomCommand(
            getStartBleStreamingAirohaCommand(), airohaDeviceListener)

        awaitClose {
        }
    }

    fun stopRaceBleStreamingFlow() = callbackFlow<AirohaStatusCode> {
            val airohaDeviceListener = object : AirohaDeviceListener {
                override fun onRead(code: AirohaStatusCode, msg: AirohaBaseMsg) {
                    logAirohaResponse("onRead", code, msg)
                    trySend(code)
                    channel.close()
                }

                override fun onChanged(code: AirohaStatusCode, msg: AirohaBaseMsg) {
                    logAirohaResponse("onChanged", code, msg)
                    trySend(code)
                    channel.close()
                }
            }

            getAirohaDeviceControl().sendCustomCommand(
                getStopBleStreamingAirohaCommand(), airohaDeviceListener)

            awaitClose {
                // Nothing to do.
            }
        }

    fun startSoundLoop() {
        if (_airohaDeviceState.value != AirohaDeviceState.READY) {
            return
        }
        getAirohaDeviceControl().sendCustomCommand(
            getStartSoundLoopAirohaCommand(), airohaDeviceListener)
    }

    fun stopSoundLoop() {
        if (_airohaDeviceState.value != AirohaDeviceState.READY) {
            return
        }
        getAirohaDeviceControl().sendCustomCommand(
            getStopSoundLoopAirohaCommand(), airohaDeviceListener)
    }

    fun changeEqualizer(gains: FloatArray) : Boolean {
        if (_airohaDeviceState.value != AirohaDeviceState.READY) {
            return false
        }
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
        return true
    }

    fun batteryLevelsFlow() = callbackFlow<AirohaBatteryLevel> {
        val batteryInfoListener = object : AirohaDeviceListener {
            override fun onRead(code: AirohaStatusCode, msg: AirohaBaseMsg?) {
                Log.d(tag,"BatteryInfoListener.onRead=${code.description}," +
                        " msg = ${msg?.msgID?.cmdName}")

                var leftBattery: Int? = null
                var rightBattery: Int? = null
                var caseBattery: Int? = null

                try {
                    if (code == AirohaStatusCode.STATUS_SUCCESS && msg != null) {
                        val batteryInfo = msg.msgContent as AirohaBatteryInfo

                        Log.d(tag,"batteryInfo master level ${batteryInfo.masterLevel}")
                        Log.d(tag, "batteryInfo slave level ${batteryInfo.slaveLevel}")
                        Log.d(tag,"AirohaSDK.getInst().isAgentRightSideDevice()=" +
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
                    Log.e(tag, e.message, e)
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
        } else {
            val eegSamplingRate = _airohaBleManager?.getEegSamplingRate() ?: 1000f
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
    }

    private fun twsConnectStatusFlow() = callbackFlow<Boolean?> {
        val twsConnectStatusListener = object : AirohaDeviceListener {
                override fun onRead(code: AirohaStatusCode, msg: AirohaBaseMsg) {
                    Log.d(tag, "TwsConnectStatusListener.onRead=${code.description}," +
                            " msg = ${msg.msgID.cmdName}")
                    try {
                        if (code == AirohaStatusCode.STATUS_SUCCESS) {
                            val isTwsConnected = msg.msgContent as Boolean
                            Log.d(tag, "isTwsConnected=$isTwsConnected")
                            trySend(isTwsConnected)
                        } else {
                            Log.d(tag, "getTwsConnectStatus: ${code.description}," +
                                    " msg = ${msg.msgID.cmdName}")
                            trySend(null)
                        }
                    } catch (e: java.lang.Exception) {
                        Log.e(tag, e.message, e)
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
                Log.d(tag, "DeviceInfoListener.onRead=${code.description}," +
                        " msg = ${msg.msgID.cmdName}")
                try {
                    if (code == AirohaStatusCode.STATUS_SUCCESS) {
                        Log.d(tag, "Parsing DeviceInfo")
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
                    Log.e(tag, e.message, e)
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

    private fun getStartSoundLoopAirohaCommand(): AirohaCmdSettings {
        val raceCommand = AirohaCmdSettings()
        raceCommand.respType = RaceType.INDICATION
        raceCommand.command = StartStopSoundLoopRaceCommand(
            StartStopSoundLoopRaceCommand.SoundLoopType.START_LOOP).getBytes()
        Log.d(tag, "getStartStopSoundLoopAirohaCommand: ${Converter.byte2HexStr(raceCommand.command)}")
        return raceCommand
    }

    private fun getStopSoundLoopAirohaCommand(): AirohaCmdSettings {
        val raceCommand = AirohaCmdSettings()
        raceCommand.respType = RaceType.INDICATION
        raceCommand.command = StartStopSoundLoopRaceCommand(
            StartStopSoundLoopRaceCommand.SoundLoopType.STOP_LOOP).getBytes()
        Log.d(tag, "getStartStopSoundLoopAirohaCommand: ${Converter.byte2HexStr(raceCommand.command)}")
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
        // Need to start the service explicitly so that 'onStartCommand' gets called in the service.
        context.startService(_budzServiceIntent)
        context.bindService(_budzServiceIntent!!, serviceConnection, Context.BIND_AUTO_CREATE)
    }

    private fun stopService() {
        if (_budzServiceIntent == null) {
            return
        }
        if (_budzServiceBound && _budzServiceConnection != null) {
            try {
                context.unbindService(_budzServiceConnection!!)
            } catch (e: IllegalArgumentException) {
                Log.w(tag, e.message, e)
            } finally {
                _budzServiceBound = false
                _budzServiceConnection = null
            }
       }
        context.stopService(_budzServiceIntent)
        _budzService = null
    }

    private fun isAirohaDeviceBonded(): Boolean {
        val bonded: Boolean = _devicePresenter?.findAirohaDevice() ?: false
        _airohaDeviceState.value = if (bonded) AirohaDeviceState.BONDED else
            AirohaDeviceState.DISCONNECTED
        Log.i(tag, "isAirohaDeviceBonded=$bonded")
        return bonded
    }

    private fun connectAirohaDevice() {
        _devicePresenter?.connectBoundDevice()
    }
}