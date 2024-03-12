package io.nextsense.android.main.presentation

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Devices
import androidx.compose.ui.tooling.preview.Preview
import androidx.wear.compose.material.Button
import androidx.wear.compose.material.Text
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.MultiplePermissionsState
import com.google.accompanist.permissions.PermissionState
import io.nextsense.android.main.data.DataTypeAvailability
import io.nextsense.android.main.lucid.dev.R
import io.nextsense.android.main.theme.LucidWatchTheme

@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun HeartRateScreen(
    hr: Double,
    availability: DataTypeAvailability,
    enabled: Boolean,
    onButtonClick: () -> Unit,
    multiPermissionsState: MultiplePermissionsState
) {
    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        HrLabel(
            hr = hr, availability = availability
        )
        Button(modifier = Modifier.fillMaxWidth(0.5f), onClick = {
            if (multiPermissionsState.allPermissionsGranted) {
                onButtonClick()
            } else {
                multiPermissionsState.launchMultiplePermissionRequest()
            }
        }) {
            val buttonTextId = if (enabled) {
                R.string.stop
            } else {
                R.string.start
            }
            Text(stringResource(buttonTextId))
        }
    }
}

@ExperimentalPermissionsApi
@Preview(
    device = Devices.WEAR_OS_SMALL_ROUND, showBackground = false, showSystemUi = true
)
@Composable
fun HeartRateScreenPreview() {
    val multiPermissionsState = object : MultiplePermissionsState {
        override val allPermissionsGranted: Boolean
            get() = false
        override val permissions: List<PermissionState>
            get() = listOf()
        override val revokedPermissions: List<PermissionState>
            get() = listOf()
        override val shouldShowRationale: Boolean
            get() = false

        override fun launchMultiplePermissionRequest() {
        }
    }
    LucidWatchTheme {
        HeartRateScreen(
            hr = 65.0,
            availability = DataTypeAvailability.AVAILABLE,
            enabled = false,
            onButtonClick = {},
            multiPermissionsState = multiPermissionsState
        )
    }
}
