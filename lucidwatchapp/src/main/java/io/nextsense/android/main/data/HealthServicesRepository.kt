/*
 * Copyright 2022 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package io.nextsense.android.main.data

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.util.Log
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableStateOf
import androidx.concurrent.futures.await
import androidx.health.services.client.HealthServices
import androidx.health.services.client.MeasureCallback
import androidx.health.services.client.data.Availability
import androidx.health.services.client.data.DataPointContainer
import androidx.health.services.client.data.DataType
import androidx.health.services.client.data.DataTypeAvailability
import androidx.health.services.client.data.DeltaDataType
import androidx.health.services.client.data.SampleDataPoint
import io.nextsense.android.main.TAG
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.channels.trySendBlocking
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.runBlocking
import java.time.Duration

/**
 * Entry point for [HealthServicesClient] APIs. This also provides suspend functions around
 * those APIs to enable use in coroutines.
 */
class HealthServicesRepository(context: Context) {
    private val healthServicesClient = HealthServices.getClient(context)
    private val measureClient = healthServicesClient.measureClient
    val availability: MutableState<DataTypeAvailability> =
        mutableStateOf(DataTypeAvailability.UNKNOWN)

    suspend fun hasHeartRateCapability(): Boolean {
        val capabilities = measureClient.getCapabilitiesAsync().await()
        return (DataType.HEART_RATE_BPM in capabilities.supportedDataTypesMeasure)
    }

    /**
     * Returns a cold flow. When activated, the flow will register a callback for heart rate data
     * and start to emit messages. When the consuming coroutine is cancelled, the measure callback
     * is unregistered.
     *
     * [callbackFlow] is used to bridge between a callback-based API and Kotlin flows.
     */
    fun heartRateMeasureFlow() = callbackFlow {
        val callback = object : MeasureCallback {
            override fun onAvailabilityChanged(
                dataType: DeltaDataType<*, *>, availability: Availability
            ) {
                // Only send back DataTypeAvailability (not LocationAvailability)
                if (availability is DataTypeAvailability) {
                    this@HealthServicesRepository.availability.value = availability
                    trySendBlocking(MeasureMessage.MeasureAvailability(availability))
                }
            }

            override fun onDataReceived(data: DataPointContainer) {
                val heartRateBpm = data.getData(DataType.HEART_RATE_BPM)
                trySendBlocking(MeasureMessage.MeasureData(heartRateBpm))
            }
        }

        Log.d(TAG, "Registering for data")
        measureClient.registerMeasureCallback(DataType.HEART_RATE_BPM, callback)
        awaitClose {
            Log.d(TAG, "Unregistering for data")
            runBlocking {
                measureClient.unregisterMeasureCallbackAsync(DataType.HEART_RATE_BPM, callback)
                    .await()
            }
        }
    }

    fun heartRateMeasureForegroundFlow(context: Context) = callbackFlow {
        val sensorManager = context.getSystemService(SensorManager::class.java)
        val heartRateSensor = sensorManager.getDefaultSensor(Sensor.TYPE_HEART_RATE)
        if (heartRateSensor == null) {
            trySendBlocking(MeasureMessage.MeasureAvailability(DataTypeAvailability.UNAVAILABLE))
        } else {
            trySendBlocking(MeasureMessage.MeasureAvailability(DataTypeAvailability.AVAILABLE))
        }
        val sensorEvent = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent?) {
                event?.let {
                    if (it.sensor == heartRateSensor) {
                        Log.i(TAG, "Heart rate data measurement")
                        val mHeartRateFloat = event.values[0]
                        trySendBlocking(
                            MeasureMessage.MeasureData(
                                listOf(
                                    SampleDataPoint(
                                        DataType.HEART_RATE_BPM,
                                        mHeartRateFloat.toDouble(),
                                        Duration.ofMillis(event.timestamp)
                                    )
                                )
                            )
                        )
                    }
                }
            }

            override fun onAccuracyChanged(p0: Sensor?, p1: Int) {
            }
        }
        Log.d(TAG, "Registering for data")
        sensorManager?.registerListener(
            sensorEvent, heartRateSensor, SensorManager.SENSOR_DELAY_FASTEST
        )
        awaitClose {
            Log.d(TAG, "Unregistering for data")
            runBlocking {
                sensorManager?.unregisterListener(sensorEvent)
            }
        }
    }
}

sealed class MeasureMessage {
    class MeasureAvailability(val availability: DataTypeAvailability) : MeasureMessage()
    class MeasureData(val data: List<SampleDataPoint<Double>>) : MeasureMessage()
}
