package io.nextsense.android.budz.manager

import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentReference
import io.nextsense.android.base.data.LocalSessionManager
import io.nextsense.android.base.utils.RotatingFileLogger
import io.nextsense.android.budz.BuildConfig
import io.nextsense.android.budz.State
import io.nextsense.android.budz.model.DataSession
import io.nextsense.android.budz.model.Modality
import io.nextsense.android.budz.model.Session
import io.nextsense.android.budz.model.SessionsRepository
import java.util.TimeZone

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

    suspend fun startSession(protocol: Protocol, uploadToCloud: Boolean = false) : Boolean {
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
        val startTime = Timestamp.now()

        // Create the session in Firestore.
        val session = Session(
            startDatetime = startTime,
            deviceId = deviceInfo.deviceMAC,
            deviceMacAddress = deviceInfo.deviceMAC,
            deviceFirmwareVersion = deviceInfo.firmwareVer,
            deviceVersion = deviceInfo.devicePid,
            earbudsConfig = EarbudsConfigNames.MAUI_CONFIG.key(),
            mobileAppVersion = appVersion,
            protocolName = protocol.key(),
            timezone = TimeZone.getDefault().id,
            userId = userId,
            createdAt = Timestamp.now()
        )
        val sessionState = sessionsRepository.addSession(session)
        if (sessionState is State.Success) {
            RotatingFileLogger.get().logi(tag, "Session created in Firestore successfully." +
                    " id=${sessionState.data.id}")
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
            haveRawData = false,
            createdAt = Timestamp.now()
        )
        val dataSessionState = sessionsRepository.addDataSession(
            dataSession, _currentSessionRef!!.id)
        if (dataSessionState is State.Success) {
            _currentDataSession = dataSession
            RotatingFileLogger.get().logi(tag, "Data session created in Firestore successfully." +
                    " id=${dataSessionState.data.id}")
        } else {
            RotatingFileLogger.get().logw(tag, "Failed to create Firestore data session.")
            return false
        }
        _currentDataSessionRef = dataSessionState.data

        val localSessionId: Long = localSessionManager.startLocalSession(
            /*cloudDataSessionId=*/_currentSessionRef!!.id,
            /*userBigTableKey=*/_currentSessionRef!!.id,
            EarbudsConfigNames.MAUI_CONFIG.key(), uploadToCloud,
            airohaDeviceManager.getEegSamplingRate(), /*accelerationSampleRate=*/100F,
            /*saveToCsv=*/true)
        if (localSessionId == -1L) {
            // TODO(eric): delete cloud session on error.
            // Previous session not finished, cannot start streaming.
            RotatingFileLogger.get()
                .logw(tag, "Previous session not finished, cannot start streaming.")
            return false
        }
        _currentSession = session
        _currentDataSession = dataSession

        // TODO(eric): Check result.
        airohaDeviceManager.startBleStreaming()
        return true
    }

    suspend fun stopSession() {
        if (_currentSessionRef == null || _currentDataSessionRef == null ||
            _currentSession == null || _currentDataSession == null) {
            RotatingFileLogger.get().logw(tag, "Tried to stop a session while none was running.")
            return
        }

        // TODO(eric): Check result.
        airohaDeviceManager.stopBleStreaming()

        val stopTime = Timestamp.now()
        localSessionManager.stopActiveLocalSession()

        _currentSession!!.endDatetime = stopTime
        val sessionState = sessionsRepository.updateSession(_currentSession!!, _currentSessionRef!!.id)
        if (sessionState is State.Success) {
            RotatingFileLogger.get().logi(tag, "Session updated successfully.")
        } else {
            RotatingFileLogger.get().logw(tag, "Failed to update session.")
        }

        _currentDataSession!!.endDatetime = stopTime
        val dataSessionState = sessionsRepository.updateDataSession(
            _currentDataSession!!, _currentSessionRef!!.id, _currentDataSessionRef!!.id)
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
}