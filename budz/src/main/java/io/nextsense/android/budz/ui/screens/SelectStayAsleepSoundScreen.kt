package io.nextsense.android.budz.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.LifecycleStartEffect
import io.nextsense.android.budz.R
import io.nextsense.android.budz.manager.SoundsManager
import io.nextsense.android.budz.ui.components.AudioSampleList
import io.nextsense.android.budz.ui.components.LoadingCircle
import io.nextsense.android.budz.ui.components.TopBar

@Composable
fun SelectStayAsleepSoundScreen(
        stayAsleepViewModel: SelectStayAsleepSoundViewModel = hiltViewModel(),
        onNavigateBack: () -> Unit) {
    val stayAsleepUiState by stayAsleepViewModel.uiState.collectAsState()
    val context = LocalContext.current

    LifecycleStartEffect(true) {
        onStopOrDispose {
            SoundsManager.stopAudioSample()
        }
    }

    Scaffold(
        topBar = {
            TopBar(title = stringResource(R.string.title_stay_asleep), isAppTitle = false,
                showHome = false, showPrivacy = false, onNavigationClick = { onNavigateBack() })
        },
        modifier = Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background)
    ) {
        Surface(
            modifier = Modifier
                .fillMaxSize()
                .padding(it)
        ) {
            Column(
                verticalArrangement = Arrangement.Top,
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.padding(horizontal = 30.dp)
                    .verticalScroll(rememberScrollState())
            ) {
                Column {
                    if (stayAsleepUiState.loading) {
                        LoadingCircle()
                    }
                    Row {
                        Column {
                            AudioSampleList(
                                audioGroups = SoundsManager.stayAsleepSamples,
                                selected = stayAsleepUiState.audioSample,
                                playing = stayAsleepUiState.playing,
                                enabled = !stayAsleepUiState.loading,
                                onSelect = { audioSample ->
                                    stayAsleepViewModel.playAudioSample(context, audioSample)
                                    stayAsleepViewModel.changeStayAsleepSound(audioSample)
                                },
                                onStop = { stayAsleepViewModel.stopPlayingSample() }
                            )
                        }
                    }
                }
            }
        }
    }
}