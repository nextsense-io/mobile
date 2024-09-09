package io.nextsense.android.budz.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.LifecycleStartEffect
import io.nextsense.android.budz.R
import io.nextsense.android.budz.manager.SessionState
import io.nextsense.android.budz.model.ActivityType
import io.nextsense.android.budz.model.DataQuality
import io.nextsense.android.budz.model.ToneBud
import io.nextsense.android.budz.ui.components.StringListDropDown
import io.nextsense.android.budz.ui.components.TopBar
import io.nextsense.android.budz.ui.components.TopBarLeftIconContent
import io.nextsense.android.budz.ui.components.WideButton

@Composable
fun DataCollectionScreen(
    dataCollectionViewModel: DataCollectionViewModel = hiltViewModel(),
    onGoBack: () -> Unit) {

    val uiState by dataCollectionViewModel.uiState.collectAsState()

    LifecycleStartEffect(true) {
        dataCollectionViewModel.startMonitoring()
        onStopOrDispose {
            dataCollectionViewModel.stopMonitoring()
        }
    }

    val startStopEnabled = uiState.connected &&
            ((uiState.recordingState == SessionState.STARTED &&
                    uiState.dataQuality != DataQuality.UNKNOWN) ||
                    (uiState.recordingState == SessionState.STOPPED &&
                            uiState.activityType != ActivityType.UNKNOWN &&
                            uiState.toneBud != ToneBud.UNKNOWN))

    Scaffold(
        topBar = {
            TopBar(title = stringResource(R.string.app_title), isAppTitle = true,
                leftIconContent = TopBarLeftIconContent.BACK, showPrivacy = false,
                onNavigationClick = onGoBack )
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
                verticalArrangement = Arrangement.Top,
                horizontalAlignment = Alignment.Start,
                modifier = Modifier
                    .padding(horizontal = 30.dp)
                    .verticalScroll(rememberScrollState())
            ) {
                Spacer(modifier = Modifier.height(20.dp))
                Row {
                    Text(
                        text = "Activity",
                        style = MaterialTheme.typography.labelMedium,
                        textAlign = TextAlign.Start,
                        modifier = Modifier.align(Alignment.CenterVertically)
                    )
                    Spacer(modifier = Modifier.width(20.dp))
                    StringListDropDown(
                        options = ActivityType.entries.map {activityType -> activityType.label },
                        currentSelection = uiState.activityType.label,
                        enabled = uiState.recordingState == SessionState.STOPPED,
                        modifier = Modifier.width(400.dp),
                        onChange = { label ->
                            dataCollectionViewModel.setActivityType(ActivityType.fromLabel(label)) }
                    )
                }
                Spacer(modifier = Modifier.height(40.dp))
                Row {
                    Text(
                        text = "Bud",
                        style = MaterialTheme.typography.labelMedium,
                        modifier = Modifier.align(Alignment.CenterVertically)
                    )
                    Spacer(modifier = Modifier.width(20.dp))
                    StringListDropDown(
                        options = ToneBud.entries.map { toneBud -> toneBud.label },
                        currentSelection = uiState.toneBud.label,
                        enabled = uiState.recordingState == SessionState.STOPPED,
                        modifier = Modifier.width(400.dp),
                        onChange = { label ->
                            dataCollectionViewModel.setToneBud(ToneBud.fromLabel(label)) }
                    )
                }
                Spacer(modifier = Modifier.height(40.dp))
                Row {
                    Text(
                        text = "Data Quality",
                        style = MaterialTheme.typography.labelMedium,
                        modifier = Modifier.align(Alignment.CenterVertically)
                    )
                    Spacer(modifier = Modifier.width(20.dp))
                    StringListDropDown(
                        options = DataQuality.entries.map { dataQuality -> dataQuality.label },
                        currentSelection = uiState.dataQuality.label,
                        enabled = uiState.recordingState == SessionState.STARTED,
                        modifier = Modifier.width(400.dp),
                        onChange = { label ->
                            dataCollectionViewModel.setDataQuality(DataQuality.fromLabel(label)) }
                    )
                }
                Spacer(modifier = Modifier.height(40.dp))
                val buttonLabel = when (uiState.recordingState) {
                    SessionState.STARTED -> "Stop Recording"
                    SessionState.STARTING -> "Starting..."
                    SessionState.STOPPING -> "Stopping..."
                    else -> "Start Recording"
                }
                WideButton(name = buttonLabel, enabled = startStopEnabled, onClick = {
                        dataCollectionViewModel.startStopRecording()
                    })
            }
        }
    }
}