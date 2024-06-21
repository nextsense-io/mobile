package io.nextsense.android.budz.ui.screens

import android.Manifest
import android.os.Build
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.rememberMultiplePermissionsState
import io.nextsense.android.budz.R
import io.nextsense.android.budz.ui.components.BudzCard
import io.nextsense.android.budz.ui.components.TopBar
import io.nextsense.android.budz.ui.components.WideButton
import io.nextsense.android.budz.ui.theme.BudzColor

@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun CheckConnectionScreen(
    checkConnectionViewModel: CheckConnectionViewModel = hiltViewModel(),
    onGoToHome: () -> Unit,
    onGoToConnectionGuide: () -> Unit,
    onGoToFitGuide: () -> Unit,
    onGoToCheckBrainSignal: () -> Unit,
) {
    val checkConnectionUiState by checkConnectionViewModel.uiState.collectAsState()

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        val bluetoothConnectPermissionsState = rememberMultiplePermissionsState(
            permissions = listOf(
                Manifest.permission.BLUETOOTH_CONNECT,
                Manifest.permission.BLUETOOTH_SCAN
            )
        )

        LaunchedEffect(bluetoothConnectPermissionsState) {
            bluetoothConnectPermissionsState.launchMultiplePermissionRequest()
        }
    }

    Scaffold(
        topBar = {
            TopBar(title = stringResource(R.string.app_title), isAppTitle = true, showBack = true,
                showHome = false, showPrivacy = false, onNavigationClick = { onGoToHome() })
        },
        modifier = Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background)
    ) {
        Surface(
            modifier = Modifier
                .fillMaxSize()
                .padding(it)
        ) {
            Column(
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.padding(horizontal = 30.dp)
                    .verticalScroll(rememberScrollState())
            ) {
                BudzCard {
                    Column(modifier = Modifier.fillMaxWidth()) {
                        Text(
                            text = stringResource(R.string.label_bluetooth_status),
                            style = MaterialTheme.typography.displayMedium
                        )
                        if (checkConnectionUiState.connected) {
                            Text(
                                text = stringResource(R.string.label_connected),
                                style = MaterialTheme.typography.titleSmall.copy(color = BudzColor.green),
                                modifier = Modifier.padding(bottom = 20.dp)
                            )
                        } else {
                            Text(
                                text = stringResource(R.string.label_disconnected),
                                style = MaterialTheme.typography.titleSmall.copy(color = BudzColor.red),
                                modifier = Modifier.padding(bottom = 20.dp)
                            )
                        }
                    }
                }
                Spacer(modifier = Modifier.height(20.dp))
                TextButton(
                    onClick = { onGoToCheckBrainSignal() }
                ) {
                    Text(stringResource(R.string.label_check_brain_signal),
                        style = MaterialTheme.typography.labelLarge.copy(color = Color.White))
                }
                Spacer(modifier = Modifier.weight(1f))
                WideButton(
                    name = stringResource(R.string.label_bluetooth_connection_guide),
                    onClick = { onGoToConnectionGuide() },
                    modifier = Modifier.padding(bottom = 20.dp)
                )
                WideButton(
                    name = stringResource(R.string.label_fit_guide),
                    onClick = { onGoToFitGuide() }
                )
                Spacer(modifier = Modifier.height(20.dp))
            }
        }
    }
}