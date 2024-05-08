package io.nextsense.android.budz.ui.screens

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.compose.LifecycleStartEffect
import androidx.lifecycle.viewmodel.compose.viewModel
import io.nextsense.android.budz.manager.SoundsManager
import io.nextsense.android.budz.ui.components.AudioSampleList
import io.nextsense.android.budz.ui.components.LoadingCircle
import io.nextsense.android.budz.ui.components.Title

@Composable
fun SelectStayAsleepSoundScreen(stayAsleepViewModel: SelectStayAsleepSoundViewModel = viewModel()) {
    val stayAsleepUiState by stayAsleepViewModel.uiState.collectAsState()
    val context = LocalContext.current

    LifecycleStartEffect {
        onStopOrDispose {
            SoundsManager.stopAudioSample()
        }
    }

    Column {
        Title("Select sound to play to stay asleep")
        if (stayAsleepUiState.loading) {
            LoadingCircle()
        }
        Row {
            Spacer(modifier = Modifier.weight(1f))
            Column {
                AudioSampleList(
                    audioSamples = SoundsManager.stayAsleepSamples,
                    selected = stayAsleepUiState.audioSample,
                    playing = stayAsleepUiState.playing,
                    enabled = !stayAsleepUiState.loading,
                    onSelect = {audioSample ->
                        stayAsleepViewModel.playAudioSample(context, audioSample)
                        stayAsleepViewModel.changeStayAsleepSound(audioSample)
                    },
                    onStop = {stayAsleepViewModel.stopPlayingSample()}
                )
            }
            Spacer(modifier = Modifier.weight(1f))
        }
    }
}