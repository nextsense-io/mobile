package io.nextsense.android.budz.ui.screens

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.LifecycleStartEffect
import io.nextsense.android.budz.manager.SoundsManager
import io.nextsense.android.budz.ui.components.AudioSampleList
import io.nextsense.android.budz.ui.components.LoadingCircle
import io.nextsense.android.budz.ui.components.Title

@Composable
fun SelectFallAsleepSoundScreen(
        stayAsleepViewModel: SelectFallAsleepSoundViewModel = hiltViewModel()) {
    val stayAsleepUiState by stayAsleepViewModel.uiState.collectAsState()
    val context = LocalContext.current

    LifecycleStartEffect(true) {
        onStopOrDispose {
            SoundsManager.stopAudioSample()
        }
    }

    Column {
        Title("Select sound to play to fall asleep")
        if (stayAsleepUiState.loading) {
            LoadingCircle()
        }
        Row {
            Spacer(modifier = Modifier.weight(1f))
            Column {
                AudioSampleList(
                    audioSamples = SoundsManager.fallAsleepSamples,
                    selected = stayAsleepUiState.audioSample,
                    playing = stayAsleepUiState.playing,
                    enabled = !stayAsleepUiState.loading,
                    onSelect = {audioSample ->
                        stayAsleepViewModel.playAudioSample(context, audioSample)
                        stayAsleepViewModel.changeFallAsleepSound(audioSample)
                    },
                    onStop = {stayAsleepViewModel.stopPlayingSample()}
                )
            }
            Spacer(modifier = Modifier.weight(1f))
        }
    }
}