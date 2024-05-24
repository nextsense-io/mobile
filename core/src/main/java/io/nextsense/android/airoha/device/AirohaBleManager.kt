package io.nextsense.android.airoha.device

import io.nextsense.android.base.Device
import io.nextsense.android.base.DeviceManager
import io.nextsense.android.base.DeviceScanner.ScanError
import io.nextsense.android.base.DeviceState
import io.nextsense.android.base.utils.RotatingFileLogger
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import java.util.concurrent.TimeUnit

/**
 * Manages the communication through BLE for both right and left devices.
 */
class AirohaBleManager constructor(
    private val deviceManager: DeviceManager
) {
    private val tag = AirohaBleManager::class.java.simpleName
    private var leftEarDevice: Device? = null
    private var rightEarDevice: Device? = null

    fun connectFlow() = flow {
        emit(DeviceState.CONNECTING)
        deviceScanListenerFlow().collect {device ->
            leftEarDevice = device
            try {
                val deviceStateFuture = device?.connect(/*autoReconnect=*/true)
                val deviceState = deviceStateFuture?.get(5, TimeUnit.SECONDS)
                emit(deviceState)
            } catch (e: Exception) {
                RotatingFileLogger.get().loge(tag,
                    "Error while connecting to device: ${e.message}")
                emit(DeviceState.DISCONNECTED)
            }
        }
    }.flowOn(Dispatchers.IO)

    fun startStreamingFlow() = flow<Boolean> {
        leftEarDevice?.let { device ->
            try {
                val started = device.startStreaming(
                    /*uploadToCloud=*/false,
                    /*userBigTableKey=*/null,
                    /*dataSessionId=*/null,
                    /*earbudsConfig=*/null,
                    /*saveToCsv=*/false
                ).get(5, TimeUnit.SECONDS)
                emit(started)
            } catch (e: Exception) {
                RotatingFileLogger.get().loge(tag,
                    "Error while starting streaming: ${e.message}")
                emit(false)
            }
        }
        rightEarDevice?.let { device ->
            try {
                val started = device.startStreaming(
                    /*uploadToCloud=*/false,
                    /*userBigTableKey=*/null,
                    /*dataSessionId=*/null,
                    /*earbudsConfig=*/null,
                    /*saveToCsv=*/false
                ).get(5, TimeUnit.SECONDS)
                emit(started)
            } catch (e: Exception) {
                RotatingFileLogger.get().loge(tag,
                    "Error while starting streaming: ${e.message}")
                emit(false)
            }
        }
        if (leftEarDevice == null && rightEarDevice == null) {
            emit(false)
        }
    }.flowOn(Dispatchers.IO)

    fun deviceScanListenerFlow() = callbackFlow<Device?> {
        val deviceScanListener = object : DeviceManager.DeviceScanListener {
            override fun onNewDevice(device: Device) {
                RotatingFileLogger.get()
                    .logi(tag, "Found a device in Android scan: " + device.name)
                trySend(device)
            }

            override fun onScanError(scanError: ScanError) {
                RotatingFileLogger.get().loge(
                    tag,
                    "Error while scanning in Android: " + scanError.name
                )
                trySend(null)
            }
        }

        deviceManager.findDevices(deviceScanListener)

        awaitClose {
            deviceManager.stopFindingDevices(deviceScanListener)
        }
    }.flowOn(Dispatchers.IO)

    fun disconnect() {
        leftEarDevice?.let {
            it.disconnect()
        }
        rightEarDevice?.let {
            it.disconnect()
        }
    }

    fun startStreaming() {
        leftEarDevice?.let {
            it.startStreaming(/*uploadToCloud=*/false, /*userBigTableKey=*/null, /*dataSessionId=*/null,
                /*earbudsConfig=*/null, /*saveToCsv=*/false)
        }
        rightEarDevice?.let {
            it.startStreaming(/*uploadToCloud=*/false, /*userBigTableKey=*/null, /*dataSessionId=*/null,
                /*earbudsConfig=*/null, /*saveToCsv=*/false)
        }
    }

    fun stopStreaming() {
        leftEarDevice?.let {
            it.stopStreaming()
        }
        rightEarDevice?.let {
            it.stopStreaming()
        }
    }
}