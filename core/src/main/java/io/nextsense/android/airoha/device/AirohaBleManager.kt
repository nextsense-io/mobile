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
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.take
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.suspendCancellableCoroutine
import java.util.concurrent.CompletableFuture
import java.util.concurrent.TimeUnit
import kotlin.coroutines.resumeWithException

/**
 * Manages the communication through BLE for both right and left devices.
 */
class AirohaBleManager(
    private val deviceManager: DeviceManager
) {
    private val tag = AirohaBleManager::class.java.simpleName
    private var leftEarDevice: Device? = null
    private var rightEarDevice: Device? = null
    private var leftDeviceState: DeviceState? = null
    private var rightDeviceState: DeviceState? = null

    suspend fun <T> CompletableFuture<T>.await(): T {
        return suspendCancellableCoroutine { cont ->
            whenComplete { result, exception ->
                if (exception == null) {
                    cont.resume(result) { }
                } else {
                    cont.resumeWithException(exception)
                }
            }

            cont.invokeOnCancellation {
                cancel(true)
            }
        }
    }

    suspend fun connect(): DeviceState {
        val devices = deviceScanListenerFlow().take(1).toList()
        for (device in devices) {
            if (device?.name == MauiDevice.BLUETOOTH_PREFIX_LEFT) {
                leftEarDevice = device
            } else if (device?.name == MauiDevice.BLUETOOTH_PREFIX_RIGHT) {
                rightEarDevice = device
            } else {
                RotatingFileLogger.get().logw(tag, "Found a device with unknown name: " +
                        "${device?.name}")
            }
            try {
                val deviceConnectFuture = CompletableFuture.supplyAsync {
                    device?.connect(/*autoReconnect=*/true)?.get(5, TimeUnit.SECONDS)
                }
                val deviceState = deviceConnectFuture.await()
                if (device?.name == MauiDevice.BLUETOOTH_PREFIX_LEFT) {
                    leftDeviceState = deviceState
                } else if (device?.name == MauiDevice.BLUETOOTH_PREFIX_RIGHT) {
                    rightDeviceState = deviceState
                }
            } catch (e: Exception) {
                RotatingFileLogger.get().loge(tag,
                    "Error while connecting to device: ${e.message}")
                return DeviceState.DISCONNECTED
            }
        }
        if (leftEarDevice != null || rightEarDevice != null) {
            if (leftDeviceState == DeviceState.READY || rightDeviceState == DeviceState.READY) {
                return DeviceState.READY
            }
        } else if (leftEarDevice != null) {
            return leftDeviceState ?: DeviceState.DISCONNECTED
        } else if (rightEarDevice != null) {
            return rightDeviceState ?: DeviceState.DISCONNECTED
        }
        return DeviceState.DISCONNECTED
    }

    suspend fun startStreaming(): Boolean {
        val leftStarted: Boolean?
        val rightStarted: Boolean?
        try {
            val leftStartedFuture = CompletableFuture.supplyAsync {
                leftEarDevice?.startStreaming(
                    /*uploadToCloud=*/false,
                    /*userBigTableKey=*/null,
                    /*dataSessionId=*/null,
                    /*earbudsConfig=*/null,
                    /*saveToCsv=*/false
                )?.get(5, TimeUnit.SECONDS)
            }
            leftStarted = leftStartedFuture.await()
        } catch (e: Exception) {
            RotatingFileLogger.get().loge(tag,
                "Error while starting streaming: ${e.message}")
            return false
        }
        try {
            val rightStartedFuture = CompletableFuture.supplyAsync {
                rightEarDevice?.startStreaming(
                    /*uploadToCloud=*/false,
                    /*userBigTableKey=*/null,
                    /*dataSessionId=*/null,
                    /*earbudsConfig=*/null,
                    /*saveToCsv=*/false
                )?.get(5, TimeUnit.SECONDS)
            }
            rightStarted = rightStartedFuture.await()
        } catch (e: Exception) {
            RotatingFileLogger.get().loge(tag,
                "Error while starting streaming: ${e.message}")
            return false
        }
        return (leftStarted ?: false || rightStarted ?: false)
    }

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
        rightEarDevice?.disconnect()
    }

    fun stopStreaming() {
        leftEarDevice?.stopStreaming()
        rightEarDevice?.stopStreaming()
    }
}