package io.nextsense.android.airoha.device

import io.nextsense.android.base.Device
import io.nextsense.android.base.Device.DeviceStateChangeListener
import io.nextsense.android.base.DeviceManager
import io.nextsense.android.base.DeviceScanner.ScanError
import io.nextsense.android.base.DeviceState
import io.nextsense.android.base.devices.NextSenseDevice
import io.nextsense.android.base.devices.maui.MauiDevice
import io.nextsense.android.base.utils.RotatingFileLogger
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.flow.transformWhile
import kotlinx.coroutines.launch
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
    private var _leftEarDevice: Device? = null
    private var _rightEarDevice: Device? = null
    private val _leftDeviceStateFlow = MutableStateFlow(DeviceState.DISCONNECTED)
    private val _rightDeviceStateFlow = MutableStateFlow(DeviceState.DISCONNECTED)
    private val _leftDeviceStateListener: Job? = null
    private val _rightDeviceStateListener: Job? = null
    private val _scope = CoroutineScope(Dispatchers.IO)

    val leftDeviceState: StateFlow<DeviceState> = _leftDeviceStateFlow.asStateFlow()
    val rightDeviceState: StateFlow<DeviceState> = _rightDeviceStateFlow.asStateFlow()

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

    suspend fun connect(macAddress: String, twsConnected: Boolean): DeviceState {
        _leftEarDevice = null
        _rightEarDevice = null
        _leftDeviceStateFlow.value = DeviceState.DISCONNECTED
        _rightDeviceStateFlow.value = DeviceState.DISCONNECTED
        val devicesToConnect = if (twsConnected) 2 else 1
        val devices = mutableListOf<Device?>()
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
                _leftEarDevice = device
            } else if (isRightDevice(device, macAddress)) {
                _rightEarDevice = device
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
                    _leftDeviceStateFlow.value = deviceState ?: DeviceState.DISCONNECTED
                    _scope.launch { leftDeviceStateFlow().collect() }
                } else if (isRightDevice(device, macAddress)) {
                    _rightDeviceStateFlow.value = deviceState ?: DeviceState.DISCONNECTED
                    _scope.launch { rightDeviceStateFlow().collect() }
                }
            } catch (e: Exception) {
                RotatingFileLogger.get().loge(tag,
                    "Error while connecting to device: ${e.message}")
                return DeviceState.DISCONNECTED
            }
        }
        if (_leftEarDevice != null && _rightEarDevice != null) {
            if (_leftDeviceStateFlow.value == DeviceState.READY &&
                    _rightDeviceStateFlow.value == DeviceState.READY) {
                return DeviceState.READY
            }
        } else if (_leftEarDevice != null) {
            return _leftDeviceStateFlow.value
        } else if (_rightEarDevice != null) {
            return _rightDeviceStateFlow.value
        }
        return DeviceState.DISCONNECTED
    }

    suspend fun startStreaming(twsConnected: Boolean): Boolean {
        val leftStarted: Boolean?
        val rightStarted: Boolean?
        try {
            val leftStartedFuture = CompletableFuture.supplyAsync {
                _leftEarDevice?.startStreaming(
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
                _rightEarDevice?.startStreaming(
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

    public fun writeLeftBudControlCharacteristic(value: ByteArray) {
        _leftEarDevice?.writeControlCharacteristic(value)
    }

    public fun writeRightBudControlCharacteristic(value: ByteArray) {
        _rightEarDevice?.writeControlCharacteristic(value)
    }

    public fun leftBudControlCharacteristicListenerFlow() = callbackFlow<ByteArray> {
        val characteristicListener =
            NextSenseDevice.ControlCharacteristicListener { value -> trySend(value) }

        _leftEarDevice?.addControlCharacteristicListener(characteristicListener)

        awaitClose {
            _leftEarDevice?.removeControlCharacteristicListener(characteristicListener)
            channel.close()
        }
    }.flowOn(Dispatchers.IO)

    public fun rightBudControlCharacteristicListenerFlow() = callbackFlow<ByteArray> {
        val characteristicListener =
            NextSenseDevice.ControlCharacteristicListener { value -> trySend(value) }

        _rightEarDevice?.addControlCharacteristicListener(characteristicListener)

        awaitClose {
            _rightEarDevice?.removeControlCharacteristicListener(characteristicListener)
            channel.close()
        }
    }.flowOn(Dispatchers.IO)

    fun disconnect() {
        deviceManager.stopFindingAll()
        _leftEarDevice?.disconnect()
        _rightEarDevice?.disconnect()
        _leftEarDevice = null
        _rightEarDevice = null
        _leftDeviceStateListener?.cancel()
        _rightDeviceStateListener?.cancel()
        _leftDeviceStateFlow.value = DeviceState.DISCONNECTED
        _rightDeviceStateFlow.value = DeviceState.DISCONNECTED
    }

    fun stopStreaming() {
        _leftEarDevice?.stopStreaming()
        _rightEarDevice?.stopStreaming()
    }

    fun getEegSamplingRate(): Float {
        if (_leftEarDevice != null) {
            return _leftEarDevice?.settings?.eegSamplingRate ?: 1000f
        } else if (_rightEarDevice != null) {
            return _rightEarDevice?.settings?.eegSamplingRate ?: 1000f
        }
        return 1000f
    }

    private fun leftDeviceStateFlow() = callbackFlow<Boolean> {
        val leftDeviceStateFlow = DeviceStateChangeListener { newState ->
            _leftDeviceStateFlow.value = newState }

        _leftEarDevice?.addOnDeviceStateChangeListener(leftDeviceStateFlow)

        awaitClose {
            _leftEarDevice?.removeOnDeviceStateChangeListener(leftDeviceStateFlow)
            channel.close()
        }
    }

    private fun rightDeviceStateFlow() = callbackFlow<Boolean> {
        val deviceStateFlow = DeviceStateChangeListener { newState ->
            _rightDeviceStateFlow.value = newState }

        _rightEarDevice?.addOnDeviceStateChangeListener(deviceStateFlow)

        awaitClose {
            _rightEarDevice?.removeOnDeviceStateChangeListener(deviceStateFlow)
            channel.close()
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
}