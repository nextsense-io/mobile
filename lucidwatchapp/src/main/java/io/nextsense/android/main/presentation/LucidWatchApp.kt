package io.nextsense.android.main.presentation

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.wear.compose.material.Scaffold
import androidx.wear.compose.material.TimeText
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.rememberPermissionState
import io.nextsense.android.main.PERMISSION
import io.nextsense.android.main.data.HealthServicesRepository
import io.nextsense.android.main.theme.LucidWatchTheme

@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun LucidWatchApp(
    healthServicesRepository: HealthServicesRepository
) {
    LucidWatchTheme {
        Scaffold(modifier = Modifier.fillMaxSize(), timeText = { TimeText() }) {
            val viewModel: HeartRateViewModel = viewModel(
                factory = MeasureDataViewModelFactory(
                    healthServicesRepository = healthServicesRepository
                )
            )
            val enabled by viewModel.enabled.collectAsState()
            val hr by viewModel.hr
            val availability by viewModel.availability
            val uiState by viewModel.uiState

            if (uiState == UiState.Supported) {
                val permissionState = rememberPermissionState(permission = PERMISSION,
                    onPermissionResult = { granted ->
                        if (granted) viewModel.toggleEnabled()
                    })
                HeartRateScreen(
                    hr = hr,
                    availability = availability,
                    enabled = enabled,
                    onButtonClick = { viewModel.toggleEnabled() },
                    permissionState = permissionState
                )
            } else if (uiState == UiState.NotSupported) {
                NotSupportedScreen()
            }
        }
    }
}
