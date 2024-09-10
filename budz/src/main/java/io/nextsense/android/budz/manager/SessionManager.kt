package io.nextsense.android.budz.manager

import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentReference
import io.nextsense.android.base.data.Acceleration
import io.nextsense.android.base.data.AngularSpeed
import io.nextsense.android.base.data.DeviceLocation
import io.nextsense.android.base.data.LocalSessionManager
import io.nextsense.android.base.utils.RotatingFileLogger
import io.nextsense.android.budz.BuildConfig
import io.nextsense.android.budz.State
import io.nextsense.android.budz.model.ActivityType
import io.nextsense.android.budz.model.ChannelDefinition
import io.nextsense.android.budz.model.ChannelType
import io.nextsense.android.budz.model.DataQuality
import io.nextsense.android.budz.model.DataSession
import io.nextsense.android.budz.model.Modality
import io.nextsense.android.budz.model.Session
import io.nextsense.android.budz.model.SessionsRepository
import io.nextsense.android.budz.model.ToneBud
import java.util.TimeZone

enum class SessionState {
    STARTED, STARTING, STOPPING, STOPPED
}

enum class Protocol {
    SLEEP, TIMED_SLEEP, FOCUS, WAKE;

    fun key() = name.lowercase()
}

class SessionManager(
    private val airohaDeviceManager: AirohaDeviceManager,
    private val authRepository: AuthRepository,
    private val sessionsRepository: SessionsRepository,
    private val localSessionManager: LocalSessionManager,
) {
    private val tag = SessionManager::class.java.simpleName
    private val appVersion = BuildConfig.VERSION_NAME

    private var _currentSessionRef: DocumentReference? = null
    private var _currentSession: Session? = null
    val currentSession: Session? get() = _currentSession
    private var _currentDataSessionRef: DocumentReference? = null
    private var _currentDataSession: DataSession? = null
    val currentDataSession: DataSession? get() = _currentDataSession
    private var _sessionState = SessionState.STOPPED
    val sessionState: SessionState get() = _sessionState

    fun isSessionRunning(): Boolean {
        return airohaDeviceManager.streamingState.value == StreamingState.STARTING ||
                airohaDeviceManager.streamingState.value == StreamingState.STARTED
    }

    suspend fun startSession(
            protocol: Protocol, uploadToCloud: Boolean = false,
            activityType: ActivityType = ActivityType.UNKNOWN, toneBud: ToneBud = ToneBud.UNKNOWN) :
            Boolean {
        if (_sessionState != SessionState.STOPPED) {
            RotatingFileLogger.get().logw(tag, "Session already running.")
            return false
        }
        _sessionState = SessionState.STARTING
        val userId = authRepository.currentUserId
        if (userId == null) {
            RotatingFileLogger.get().logw(tag, "User id is null, cannot start a session.")
            return false
        }
        val deviceInfo = airohaDeviceManager.deviceInfo
        if (deviceInfo == null) {
            RotatingFileLogger.get().logw(tag, "Device info is null, cannot start a session.")
            return false
        }
        if (airohaDeviceManager.bleDeviceState.value != BleDeviceState.CONNECTED) {
            RotatingFileLogger.get().logw(tag, "Device is not connected, cannot start a session.")
            return false
        }

        val startTime = Timestamp.now()
        val earbudsConfig = EarbudsConfigs.getEarbudsConfig(EarbudsConfigNames.MAUI_CONFIG.name)

        if (uploadToCloud) {
            // Create the session in Firestore.
            val session = Session(
                startDatetime = startTime,
                deviceId = deviceInfo.deviceMAC,
                deviceMacAddress = deviceInfo.deviceMAC,
                deviceFirmwareVersion = deviceInfo.firmwareVer,
                deviceVersion = deviceInfo.devicePid,
                earbudsConfig = earbudsConfig.name,
                mobileAppVersion = appVersion,
                protocolName = protocol.key(),
                timezone = TimeZone.getDefault().id,
                userId = userId,
                activityType = activityType,
                toneBud = toneBud,
                createdAt = Timestamp.now()
            )
            val sessionState = sessionsRepository.addSession(session)
            if (sessionState is State.Success) {
                RotatingFileLogger.get().logi(
                    tag, "Session created in Firestore successfully." +
                            " id=${sessionState.data.id}"
                )
            } else {
                RotatingFileLogger.get().logw(tag, "Failed to create Firestore session.")
                return false
            }
            _currentSessionRef = sessionState.data

            // Create the data session in Firestore.
            val dataSession = DataSession(
                name = Modality.EEEG.key(),
                startDatetime = startTime,
                samplingRate = airohaDeviceManager.getEegSamplingRate(),
                streamingRate = airohaDeviceManager.getEegSamplingRate(),
                haveRawData = false,
                channelDefinitions = getChannelDefinitions(earbudsConfig),
                createdAt = Timestamp.now()
            )
            val dataSessionState = sessionsRepository.addDataSession(
                dataSession, _currentSessionRef!!.id
            )
            if (dataSessionState is State.Success) {
                _currentDataSession = dataSession
                RotatingFileLogger.get().logi(
                    tag, "Data session created in Firestore successfully." +
                            " id=${dataSessionState.data.id}"
                )
            } else {
                RotatingFileLogger.get().logw(tag, "Failed to create Firestore data session.")
                return false
            }
            _currentDataSessionRef = dataSessionState.data
            _currentSession = session
            _currentDataSession = dataSession
        }

        val localSessionId: Long = localSessionManager.startLocalSession(
            /*cloudDataSessionId=*/_currentSessionRef?.id,
            /*userBigTableKey=*/userId, earbudsConfig.name, uploadToCloud,
            airohaDeviceManager.getEegSamplingRate(), /*accelerationSampleRate=*/100F,
            /*saveToCsv=*/true)
        if (localSessionId == -1L) {
            // TODO(eric): delete cloud session on error.
            // Previous session not finished, cannot start streaming.
            RotatingFileLogger.get()
                .logw(tag, "Previous session not finished, cannot start streaming.")
            return false
        }

        // TODO(eric): Check result.
        airohaDeviceManager.startBleStreaming()
        _sessionState = SessionState.STARTED
        RotatingFileLogger.get().logi(tag,
            "Session started successfully. Uploading to cloud: $uploadToCloud.")
        return true
    }

    suspend fun stopSession(dataQuality: DataQuality = DataQuality.UNKNOWN) {
        if (_sessionState != SessionState.STARTED) {
            RotatingFileLogger.get().logw(tag, "Session not running.")
            return
        }
        _sessionState = SessionState.STOPPING

        // TODO(eric): Check result.
        airohaDeviceManager.stopBleStreaming(overrideForceStreaming = true)

        val stopTime = Timestamp.now()
        localSessionManager.stopActiveLocalSession()

        if (_currentSession != null) {
            _currentSession!!.endDatetime = stopTime
            _currentSession!!.dataQuality = dataQuality
            val sessionState = sessionsRepository.updateSession(
                _currentSession!!,
                _currentSessionRef!!.id
            )
            if (sessionState is State.Success) {
                RotatingFileLogger.get().logi(tag, "Session updated successfully.")
            } else {
                RotatingFileLogger.get().logw(tag, "Failed to update session.")
            }

            _currentDataSession!!.endDatetime = stopTime
            val dataSessionState = sessionsRepository.updateDataSession(
                _currentDataSession!!, _currentSessionRef!!.id, _currentDataSessionRef!!.id
            )
            if (dataSessionState is State.Success) {
                RotatingFileLogger.get().logi(tag, "Data session updated successfully.")
            } else {
                RotatingFileLogger.get().logw(tag, "Failed to update data session.")
            }

            _currentSessionRef = null
            _currentSession = null
            _currentDataSessionRef = null
            _currentDataSession = null
        }
        _sessionState = SessionState.STOPPED
        RotatingFileLogger.get().logi(tag, "Session stopped successfully.")
    }

    private fun getChannelDefinitions(earbudsConfig: EarbudsConfig): List<ChannelDefinition> {
        val channelDefinitions = mutableListOf<ChannelDefinition>()
        for (channel: EarEegChannel in earbudsConfig.channelsConfig.values) {
            channelDefinitions.add(
                ChannelDefinition(
                    name = channel.channelName(),
                    samplingRate = airohaDeviceManager.getEegSamplingRate(),
                    streamingRate = airohaDeviceManager.getEegSamplingRate(),
                    channelType = ChannelType.EEEG.name
                )
            )
        }
        for (channel in Acceleration.Channels.getForDeviceLocation(DeviceLocation.BOTH_EARBUDS)) {
            channelDefinitions.add(
                ChannelDefinition(
                    name = channel.name,
                    samplingRate = 100F,
                    streamingRate = 100F,
                    channelType = ChannelType.IMU.name
                )
            )
        }
        for (channel in AngularSpeed.Channels.getForDeviceLocation(DeviceLocation.BOTH_EARBUDS)) {
            channelDefinitions.add(
                ChannelDefinition(
                    name = channel.name,
                    samplingRate = 100F,
                    streamingRate = 100F,
                    channelType = ChannelType.IMU.name
                )
            )
        }
        channelDefinitions.add(
            ChannelDefinition(
                name = "TS",
                samplingRate = airohaDeviceManager.getEegSamplingRate(),
                streamingRate = airohaDeviceManager.getEegSamplingRate(),
                channelType = ChannelType.TIME.name
            ))
        channelDefinitions.add(
            ChannelDefinition(
                name = "MS",
                samplingRate = airohaDeviceManager.getEegSamplingRate(),
                streamingRate = airohaDeviceManager.getEegSamplingRate(),
                channelType = ChannelType.TIME.name
            ))
        return channelDefinitions
    }
}