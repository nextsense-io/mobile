package io.nextsense.android.main.presentation

import android.app.Application
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.wear.compose.material.Scaffold
import androidx.wear.compose.material.TimeText
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.rememberMultiplePermissionsState
import io.nextsense.android.main.PERMISSIONS
import io.nextsense.android.main.data.HealthServicesRepository
import io.nextsense.android.main.data.LocalDatabaseManager
import io.nextsense.android.main.theme.LucidWatchTheme

const val MILLISECONDS_PER_SECOND = 1000

@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun LucidWatchApp(
    healthServicesRepository: HealthServicesRepository,
    localDatabaseManager: LocalDatabaseManager,
) {
    LucidWatchTheme {
        Scaffold(modifier = Modifier.fillMaxSize(), timeText = { TimeText() }) {
            val viewModel: HeartRateViewModel = viewModel(
                factory = MeasureDataViewModelFactory(
                    application = LocalContext.current.applicationContext as Application,
                    healthServicesRepository = healthServicesRepository,
                    localDatabaseManager = localDatabaseManager
                )
            )
            val enabled by viewModel.enabled.collectAsState()
            val hr by viewModel.hr
            val availability by viewModel.availability
            val uiState by viewModel.uiState
            val context = LocalContext.current
            if (uiState == UiState.Supported) {
                val multiPermissionsState = rememberMultiplePermissionsState(
                    permissions = PERMISSIONS,
                    onPermissionsResult = { result ->
                        val granted = result.all { it.value }
                        if (granted) viewModel.toggleEnabled()
                    },
                )
                if (enabled) {
                    DisposableEffect(
                        key1 = Unit,
                        effect = {
                            val sensorManager = context.getSystemService(SensorManager::class.java)
                            val accelerometer =
                                sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
                            var lastSavedTimestamp = 0L
                            val sensorEvent = object : SensorEventListener {
                                override fun onSensorChanged(event: SensorEvent?) {
                                    event?.let {
                                        if (it.sensor == accelerometer) {
                                            val timestamp = System.currentTimeMillis()
                                            // Check if enough time has passed since the last saved data or it's the first data
                                            if (timestamp - lastSavedTimestamp >= MILLISECONDS_PER_SECOND || lastSavedTimestamp == 0L
                                            ) {
                                                val x = (it.values?.getOrNull(0) ?: 0).toDouble()
                                                val y = (it.values?.getOrNull(1) ?: 0).toDouble()
                                                val z = (it.values?.getOrNull(2) ?: 0f).toDouble()
                                                viewModel.saveAccelerometerData(timestamp, x, y, z)
                                                // Update the last saved timestamp
                                                lastSavedTimestamp = timestamp
                                            }
                                        }
                                    }
                                }

                                override fun onAccuracyChanged(p0: Sensor?, p1: Int) {
                                }
                            }
                            sensorManager?.registerListener(
                                sensorEvent, accelerometer, SensorManager.SENSOR_DELAY_NORMAL
                            )
                            onDispose {
                                sensorManager?.unregisterListener(sensorEvent)
                            }
                        },
                    )
                }
                HeartRateScreen(
                    hr = hr,
                    availability = availability,
                    enabled = enabled,
                    onButtonClick = {
                        viewModel.toggleEnabled()
                    },
                    multiPermissionsState = multiPermissionsState
                )
            } else if (uiState == UiState.NotSupported) {
                NotSupportedScreen()
            }
        }
    }
}
