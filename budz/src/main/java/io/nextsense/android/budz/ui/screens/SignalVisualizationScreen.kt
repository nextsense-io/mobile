package io.nextsense.android.budz.ui.screens

import android.Manifest
import android.os.Build
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.LifecycleStartEffect
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.rememberMultiplePermissionsState
import io.nextsense.android.budz.R
import io.nextsense.android.budz.ui.components.BudzCard
import io.nextsense.android.budz.ui.components.KeepScreenOn
import io.nextsense.android.budz.ui.components.SignalLineChart
import io.nextsense.android.budz.ui.components.TopBar
import io.nextsense.android.budz.ui.components.TopBarLeftIconContent
import io.nextsense.android.budz.ui.theme.BudzColor

@Composable
fun SignalVisualization(signalVisualizationViewModel: SignalVisualizationViewModel) {
    Column(modifier = Modifier.fillMaxWidth()) {
        Text(
            text = stringResource(R.string.title_brain_signal),
            style = MaterialTheme.typography.labelLarge,
            modifier = Modifier.align(Alignment.CenterHorizontally)
        )
        Spacer(modifier = Modifier.height(10.dp))
        BudzCard {
            Row {
                Text(
                    text = "L",
                    style = MaterialTheme.typography.titleSmall,
                    modifier = Modifier.align(Alignment.CenterVertically)
                )
                Spacer(modifier = Modifier.width(5.dp))
                SignalLineChart(modelProducer = signalVisualizationViewModel.leftEarChartModelProducer,
                    dataPointsSize = 1000.0, height = 200.dp)
            }
        }
        Spacer(modifier = Modifier.height(10.dp))
        BudzCard {
            Row {
                Text(
                    text = "R",
                    style = MaterialTheme.typography.titleSmall,
                    modifier = Modifier.align(Alignment.CenterVertically)
                )
                Spacer(modifier = Modifier.width(5.dp))
                SignalLineChart(signalVisualizationViewModel.rightEarChartModelProducer,
                    dataPointsSize = 1000.0, height = 200.dp)
            }
        }
    }
}

@Composable
fun CardConnected(signalVisualizationViewModel: SignalVisualizationViewModel,
                  signalVisualizationState: SignalVisualizationState) {
    BudzCard(modifier = Modifier.fillMaxWidth()) {
        Text(
            text = stringResource(R.string.label_bluetooth_status),
            style = MaterialTheme.typography.displayMedium
        )
        Text(
            text = stringResource(R.string.label_connected),
            style = MaterialTheme.typography.titleSmall.copy(color = BudzColor.green),
            modifier = Modifier.padding(bottom = 20.dp)
        )
        HorizontalDivider(color = BudzColor.lightPurple)
    }
    Column {
        Spacer(modifier = Modifier.height(10.dp))
        Row {
            Text(
                text = "Filtered",
                style = MaterialTheme.typography.labelMedium,
                modifier = Modifier.align(Alignment.CenterVertically)
            )
            Spacer(modifier = Modifier.width(10.dp))
            Switch(checked = signalVisualizationState.filtered, colors =
            SwitchDefaults.colors(
                checkedTrackColor = MaterialTheme.colorScheme.primaryContainer
            ),
                onCheckedChange = {checked ->
                    signalVisualizationViewModel.setFiltered(checked)
                })
        }
        Spacer(modifier = Modifier.height(10.dp))
        SignalVisualization(signalVisualizationViewModel)
        Spacer(modifier = Modifier.height(10.dp))
    }
}

@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun SignalVisualizationScreen(
    signalVisualizationViewModel: SignalVisualizationViewModel = hiltViewModel(),
    onGoToHome: () -> Unit,
) {
    KeepScreenOn()
    val signalVisualizationUiState by signalVisualizationViewModel.signalUiState.collectAsState()

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

    LifecycleStartEffect(true) {
        signalVisualizationViewModel.startStreaming()
        onStopOrDispose {
            signalVisualizationViewModel.stopStreaming()
        }
    }

    Scaffold(
        topBar = {
            TopBar(title = stringResource(R.string.app_title), isAppTitle = true,
                leftIconContent = TopBarLeftIconContent.BACK, showPrivacy = false,
                onNavigationClick = { onGoToHome() })
        },
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
    ) {
        Surface(
            modifier = Modifier
                .fillMaxSize()
                .padding(it)
        ) {
            Column(
                verticalArrangement = Arrangement.Center,
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier
                    .padding(horizontal = 30.dp)
                    .verticalScroll(rememberScrollState())
            ) {
                if (signalVisualizationUiState.connected) {
                    CardConnected(signalVisualizationViewModel, signalVisualizationUiState)
                } else {
                    CardNotConnected()
                }
            }
        }
    }
}
