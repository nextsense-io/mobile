package io.nextsense.android.budz.ui.screens

import androidx.annotation.OptIn
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
import androidx.lifecycle.compose.LifecycleResumeEffect
import androidx.lifecycle.compose.LifecycleStartEffect
import androidx.media3.common.util.UnstableApi
import io.nextsense.android.budz.R
import io.nextsense.android.budz.ui.components.BudzCard
import io.nextsense.android.budz.ui.components.ExoVisualizer
import io.nextsense.android.budz.ui.components.SignalLineChart
import io.nextsense.android.budz.ui.components.TopBar
import io.nextsense.android.budz.ui.components.TopBarLeftIconContent
import io.nextsense.android.budz.ui.components.WideButton

@OptIn(UnstableApi::class)
@Composable
fun BrainSignal(viewModel: BrainEqualizerViewModel) {
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
                    text = stringResource(R.string.label_left_bud),
                    style = MaterialTheme.typography.titleSmall,
                    modifier = Modifier.align(Alignment.CenterVertically)
                )
                Spacer(modifier = Modifier.width(5.dp))
                SignalLineChart(viewModel.leftEarChartModelProducer, 1000.0)
            }
        }
        Spacer(modifier = Modifier.height(10.dp))
        BudzCard {
            Row {
                Text(
                    text = stringResource(R.string.label_right_bud),
                    style = MaterialTheme.typography.titleSmall,
                    modifier = Modifier.align(Alignment.CenterVertically)
                )
                Spacer(modifier = Modifier.width(5.dp))
                SignalLineChart(viewModel.rightEarChartModelProducer, 1000.0)
            }
        }
    }
}

@OptIn(UnstableApi::class)
@Composable
fun BrainEqualizerScreen(
    brainEqualizerViewModel: BrainEqualizerViewModel = hiltViewModel(),
    onGoToCheckConnection: () -> Unit,
    onGoToConnectionGuide: () -> Unit,
    onGoToFitGuide: () -> Unit,
) {
    val brainEqualizerUiState by brainEqualizerViewModel.uiState.collectAsState()

    LifecycleResumeEffect(true) {
        brainEqualizerViewModel.startPlayer()
        onPauseOrDispose {
            brainEqualizerViewModel.pausePlayer()
        }
    }

    LifecycleStartEffect(true) {
        brainEqualizerViewModel.startStreaming()
        onStopOrDispose {
            brainEqualizerViewModel.stopStreaming()
            brainEqualizerViewModel.stopPlayer()
        }
    }

    Scaffold(
        topBar = {
            TopBar(title = stringResource(R.string.app_title), isAppTitle = true,
                leftIconContent = TopBarLeftIconContent.BACK, showPrivacy = false,
                onNavigationClick = { onGoToCheckConnection() })
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
                Text(text = stringResource(R.string.label_brain_equalizer),
                    style = MaterialTheme.typography.titleMedium,
                    textAlign = TextAlign.Start)
                Spacer(modifier = Modifier.height(10.dp))
                Text(text = stringResource(R.string.text_tune_your_music_title),
                    style = MaterialTheme.typography.bodyMedium,
                    textAlign = TextAlign.Start)
                Spacer(modifier = Modifier.height(5.dp))
                Text(text = stringResource(R.string.text_tune_your_music_content),
                    style = MaterialTheme.typography.displaySmall)
                Spacer(modifier = Modifier.height(20.dp))
                ExoVisualizer(brainEqualizerViewModel.fftAudioProcessor)
                Spacer(modifier = Modifier.height(20.dp))
                WideButton(
                    name = stringResource(R.string.label_instructions_and_tips),
                    onClick = { onGoToFitGuide() })
                Spacer(modifier = Modifier.height(20.dp))
                BrainSignal(brainEqualizerViewModel)
                Spacer(modifier = Modifier.height(20.dp))
                WideButton(
                    name = stringResource(R.string.label_fit_guide),
                    onClick = { onGoToConnectionGuide() })
            }
        }
    }
}