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
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.flow.transformWhile
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withTimeout
import java.util.concurrent.CompletableFuture
import java.util.concurrent.TimeUnit
import kotlin.coroutines.resumeWithException
import kotlin.time.Duration.Companion.seconds

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

    private fun isLeftDevice(device: Device?, macAddress: String): Boolean {
        return device?.name!!.startsWith(MauiDevice.BLUETOOTH_PREFIX_LEFT) &&
                device.name!!.endsWith(macAddress)
    }

    private fun isRightDevice(device: Device?, macAddress: String): Boolean {
        return device?.name!!.startsWith(MauiDevice.BLUETOOTH_PREFIX_RIGHT) &&
                device.name!!.endsWith(macAddress)
    }

    suspend fun connect(macAddress: String, twsConnected: Boolean): DeviceState {
        leftEarDevice = null
        rightEarDevice = null
        leftDeviceState = null
        rightDeviceState = null
        val devicesToConnect = if (twsConnected) 2 else 1
        var devices = mutableListOf<Device?>()
        try {
            withTimeout(15.seconds) {
                deviceScanListenerFlow(macAddress).transformWhile {
                    emit(it)
                    devices.add(it)
                    devices.size != devicesToConnect }.toList()
            }
        } catch (e: Exception) {
            if (devices.isEmpty()) {
                RotatingFileLogger.get().loge(tag,
                    "Error while scanning for devices: ${e.message}")
                return DeviceState.DISCONNECTED
            }
        }
        for (device in devices) {
            if (isLeftDevice(device, macAddress)) {
                leftEarDevice = device
            } else if (isRightDevice(device, macAddress)) {
                rightEarDevice = device
            } else {
                RotatingFileLogger.get().logw(tag, "Found a device with unknown name: " +
                        "${device?.name}")
            }
            try {
                val deviceConnectFuture = CompletableFuture.supplyAsync {
                    device?.connect(/*autoReconnect=*/false)?.get(30, TimeUnit.SECONDS)
                }
                val deviceState = deviceConnectFuture.await()
                if (isLeftDevice(device, macAddress)) {
                    leftDeviceState = deviceState
                } else if (isRightDevice(device, macAddress)) {
                    rightDeviceState = deviceState
                }
            } catch (e: Exception) {
                RotatingFileLogger.get().loge(tag,
                    "Error while connecting to device: ${e.message}")
                return DeviceState.DISCONNECTED
            }
        }
        if (leftEarDevice != null && rightEarDevice != null) {
            if (leftDeviceState == DeviceState.READY && rightDeviceState == DeviceState.READY) {
                return DeviceState.READY
            }
        } else if (leftEarDevice != null) {
            return leftDeviceState ?: DeviceState.DISCONNECTED
        } else if (rightEarDevice != null) {
            return rightDeviceState ?: DeviceState.DISCONNECTED
        }
        return DeviceState.DISCONNECTED
    }

    suspend fun startStreaming(twsConnected: Boolean): Boolean {
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
        return if (twsConnected) leftStarted ?: false && rightStarted ?: false else
                leftStarted ?: false || rightStarted ?: false
    }

    private fun deviceScanListenerFlow(macAddress: String) = callbackFlow<Device?> {
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

        deviceManager.findDevices(deviceScanListener, /*suffix=*/macAddress)

        awaitClose {
            deviceManager.stopFindingDevices(deviceScanListener)
            channel.close()
        }
    }.flowOn(Dispatchers.IO)

    fun disconnect() {
        deviceManager.stopFindingAll()
        leftEarDevice?.disconnect()
        rightEarDevice?.disconnect()
        leftEarDevice = null
        rightEarDevice = null
        leftDeviceState = null
        rightDeviceState = null
    }

    fun stopStreaming() {
        leftEarDevice?.stopStreaming()
        rightEarDevice?.stopStreaming()
    }

    fun getEegSamplingRate(): Float {
        if (leftEarDevice != null) {
            return leftEarDevice?.settings?.eegSamplingRate ?: 1000f
        } else if (rightEarDevice != null) {
            return rightEarDevice?.settings?.eegSamplingRate ?: 1000f
        }
        return 1000f
    }
}