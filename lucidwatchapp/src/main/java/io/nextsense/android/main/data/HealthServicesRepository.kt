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
import android.hardware.SensorManager
import javax.inject.Inject

/**
 * Entry point for [HealthServicesClient] APIs. This also provides suspend functions around
 * those APIs to enable use in coroutines.
 */
class HealthServicesRepository @Inject constructor(val context: Context) {
    suspend fun hasHeartRateCapability(): Boolean {
        val sensorManager = context.getSystemService(SensorManager::class.java)
        val heartRateSensor = sensorManager.getDefaultSensor(Sensor.TYPE_HEART_RATE)
        return heartRateSensor != null
    }
}

sealed class MeasureMessage {
    class MeasureAvailability(val availability: DataTypeAvailability) : MeasureMessage()
    class MeasureData(val data: HeartRate) : MeasureMessage()
}

sealed class DataTypeAvailability {
    data object UNKNOWN : DataTypeAvailability()
    data object AVAILABLE : DataTypeAvailability()
    data object ACQUIRING : DataTypeAvailability()
    data object UNAVAILABLE : DataTypeAvailability()
    data object UNAVAILABLE_DEVICE_OFF_BODY : DataTypeAvailability()
}

data class HeartRate(val heartRate: Double)
