package io.nextsense.android.airoha.device

import io.nextsense.android.base.Device
import io.nextsense.android.base.DeviceManager
import io.nextsense.android.base.DeviceScanner.ScanError
import io.nextsense.android.base.DeviceState
import io.nextsense.android.base.devices.maui.MauiDevice
import io.nextsense.android.base.utils.RotatingFileLogger
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import java.util.concurrent.TimeUnit

/**
 * Manages the communication through BLE for both right and left devices.
 */
class AirohaBleManager(
    private val deviceManager: DeviceManager
) {
    private val tag = AirohaBleManager::class.java.simpleName
    private var leftEarDevice: Device? = null
    private var rightEarDevice: Device? = null

    fun connectFlow() = flow {
        emit(DeviceState.CONNECTING)
        deviceScanListenerFlow().collect {device ->
            if (device?.name == MauiDevice.BLUETOOTH_PREFIX_LEFT) {
                leftEarDevice = device
//            } else if (device?.name == MauiDevice.BLUETOOTH_PREFIX_RIGHT) {
//                rightEarDevice = device
            } else {
                RotatingFileLogger.get().logw(tag, "Found a device with unknown name: " +
                        "${device?.name}")
                return@collect
            }
            try {
                val deviceStateFuture = device.connect(/*autoReconnect=*/true)
                val deviceState = deviceStateFuture?.get(5, TimeUnit.SECONDS)
                if (leftEarDevice != null) {  // && rightEarDevice != null) {
                    emit(deviceState)
                }
            } catch (e: Exception) {
                RotatingFileLogger.get().loge(tag,
                    "Error while connecting to device: ${e.message}")
                emit(DeviceState.DISCONNECTED)
            }
        }
    }.flowOn(Dispatchers.IO)

    fun startStreamingFlow() = flow<Boolean> {
        var leftStarted: Boolean? = null
        var rightStarted: Boolean? = null
        try {
            leftStarted = leftEarDevice?.startStreaming(
                /*uploadToCloud=*/false,
                /*userBigTableKey=*/null,
                /*dataSessionId=*/null,
                /*earbudsConfig=*/null,
                /*saveToCsv=*/false
            )?.get(5, TimeUnit.SECONDS)
        } catch (e: Exception) {
            RotatingFileLogger.get().loge(tag,
                "Error while starting streaming: ${e.message}")
            emit(false)
        }
//        try {
//            rightStarted = rightEarDevice?.startStreaming(
//                /*uploadToCloud=*/false,
//                /*userBigTableKey=*/null,
//                /*dataSessionId=*/null,
//                /*earbudsConfig=*/null,
//                /*saveToCsv=*/false
//            )?.get(5, TimeUnit.SECONDS)
//        } catch (e: Exception) {
//            RotatingFileLogger.get().loge(tag,
//                "Error while starting streaming: ${e.message}")
//            emit(false)
//        }
        emit(leftStarted ?: false) // && rightStarted ?: true)
    }.flowOn(Dispatchers.IO)

    private fun deviceScanListenerFlow() = callbackFlow<Device?> {
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
                cancel(CancellationException("Error while scanning in Android: " + scanError.name))
            }
        }

        deviceManager.findDevices(deviceScanListener)

        awaitClose {
            deviceManager.stopFindingDevices(deviceScanListener)
            channel.close()
        }
    }.flowOn(Dispatchers.IO)

    fun disconnect() {
        leftEarDevice?.disconnect()
//        rightEarDevice?.disconnect()
    }

    fun startStreaming() {
        leftEarDevice?.startStreaming(/*uploadToCloud=*/false, /*userBigTableKey=*/null, /*dataSessionId=*/null,
            /*earbudsConfig=*/null, /*saveToCsv=*/false)
//        rightEarDevice?.startStreaming(/*uploadToCloud=*/false, /*userBigTableKey=*/null, /*dataSessionId=*/null,
//            /*earbudsConfig=*/null, /*saveToCsv=*/false)
    }

    fun stopStreaming() {
        leftEarDevice?.stopStreaming()
//        rightEarDevice?.stopStreaming()
    }
}