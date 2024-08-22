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
import io.nextsense.android.algo.signal.BandPowerAnalysis
import io.nextsense.android.budz.R
import io.nextsense.android.budz.manager.EarEegChannel
import io.nextsense.android.budz.ui.components.StringListDropDown
import io.nextsense.android.budz.ui.components.AmplitudeDropDown
import io.nextsense.android.budz.ui.components.BandDropDown
import io.nextsense.android.budz.ui.components.BudzCard
import io.nextsense.android.budz.ui.components.ExoVisualizer
import io.nextsense.android.budz.ui.components.HorizontalBandPowerBarChart
import io.nextsense.android.budz.ui.components.KeepScreenOn
import io.nextsense.android.budz.ui.components.SignalLineChart
import io.nextsense.android.budz.ui.components.SimpleButton
import io.nextsense.android.budz.ui.components.TopBar
import io.nextsense.android.budz.ui.components.TopBarLeftIconContent
import io.nextsense.android.budz.ui.components.WideButton
import io.nextsense.android.budz.ui.theme.BudzColor
import java.util.Locale

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
                SignalLineChart(viewModel.leftEarChartModelProducer, viewModel.dataPointsSize)
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
                SignalLineChart(viewModel.rightEarChartModelProducer, viewModel.dataPointsSize)
            }
        }
    }
}

@Composable
@OptIn(UnstableApi::class)
fun AlphaCharts(uiState: BrainEqualizerState) {
    Column(modifier = Modifier.fillMaxWidth()) {
        Text(
            text = "${uiState.activeBand.getName()} Brain Power",
            style = MaterialTheme.typography.labelLarge,
            modifier = Modifier.align(Alignment.CenterHorizontally)
        )
        Spacer(modifier = Modifier.height(10.dp))
        BudzCard {
            Row {
                HorizontalBandPowerBarChart(
                    xData = listOf(0F, 1F),
                    yData = listOf(uiState.leftBandPower ?: 0F, uiState.rightBandPower ?: 0F),
                    dataLabels = listOf("Left", "Right"),
                    modifier = Modifier.height(120.dp)
                )
            }
        }
    }
}

@OptIn(UnstableApi::class)
@Composable
fun BrainEqualizerScreen(
    viewModel: BrainEqualizerViewModel = hiltViewModel(),
    onGoToCheckConnection: () -> Unit,
    onGoToConnectionGuide: () -> Unit,
    onGoToFitGuide: () -> Unit,
) {
    KeepScreenOn()
    val signalUiState by viewModel.signalUiState.collectAsState()
    val uiState by viewModel.uiState.collectAsState()

    LifecycleResumeEffect(true) {
        viewModel.resumePlayer()
        onPauseOrDispose {
            viewModel.pausePlayer()
        }
    }

    LifecycleStartEffect(true) {
        viewModel.startPlayer()
        viewModel.startStreaming()
        viewModel.startModulatingSound()
        onStopOrDispose {
            viewModel.stopModulatingSound()
            viewModel.stopStreaming()
            viewModel.stopPlayer()
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
                ExoVisualizer(viewModel.fftAudioProcessor)
                Spacer(modifier = Modifier.height(20.dp))
                if (!uiState.modulationDemoMode) {
                    WideButton(
                        name = stringResource(R.string.label_instructions_and_tips),
                        onClick = { onGoToFitGuide() })
                    Spacer(modifier = Modifier.height(20.dp))
                }
                AlphaCharts(uiState)
                Spacer(modifier = Modifier.height(20.dp))
                if (!uiState.modulationDemoMode) {
                    WideButton(
                        name = stringResource(R.string.label_fit_guide),
                        onClick = { onGoToConnectionGuide() })
                } else {
                    Row {
                        BandDropDown(options = arrayListOf(BandPowerAnalysis.Band.THETA,
                            BandPowerAnalysis.Band.ALPHA, BandPowerAnalysis.Band.BETA),
                            currentSelection = uiState.activeBand,
                            enabled = !uiState.modulatingStarted,
                            onChange = {band ->
                                viewModel.changeActiveBand(band)
                            })
                        Spacer(modifier = Modifier.width(10.dp))
                        Text(
                            text = "Target",
                            style = MaterialTheme.typography.labelLarge,
                            modifier = Modifier.align(Alignment.CenterVertically)
                        )
                        Spacer(modifier = Modifier.width(20.dp))
                        AmplitudeDropDown(options = arrayListOf(2, 4, 6),
                            currentSelection = uiState.amplitudeTarget,
                            enabled = !uiState.modulatingStarted,
                            onChange = {amplitude ->
                                viewModel.changeAmplitudeTarget(amplitude)
                            })
                        Spacer(modifier = Modifier.width(20.dp))
                    }
                    Spacer(modifier = Modifier.height(20.dp))
                    Row {
                        Text(
                            text = "Side",
                            style = MaterialTheme.typography.labelLarge,
                            modifier = Modifier.align(Alignment.CenterVertically)
                        )
                        Spacer(modifier = Modifier.width(20.dp))
                        StringListDropDown(options = viewModel.getChannels(),
                            currentSelection = uiState.activeChannel.alias,
                            enabled = !uiState.modulatingStarted,
                            modifier = Modifier.width(140.dp),
                            onChange = {alias ->
                                viewModel.changeActiveChannel(
                                    EarEegChannel.getChannelByAlias(alias))
                            })
                        Spacer(modifier = Modifier.width(20.dp))
                        if (uiState.modulationDifference != null)
                            Text(
                                text = "Diff: ${"%.1f".format(uiState.modulationDifference)}",
                                style = MaterialTheme.typography.labelLarge.copy(
                                    color = BudzColor.green),
                                modifier = Modifier.align(Alignment.CenterVertically)
                            )
                    }
                    Spacer(modifier = Modifier.height(20.dp))
                    Row {
                        Text(
                            text = "${uiState.activeBand.getName()}: ${"%.1f".format(
                                uiState.bandPower ?: 0.0)}",
                            style = MaterialTheme.typography.labelLarge,
                            modifier = Modifier.align(Alignment.CenterVertically)
                        )
                        Spacer(modifier = Modifier.width(60.dp))
                        SimpleButton(name = if (uiState.modulatingStarted) "Stop" else "Start",
                            enabled = uiState.bandPower != null,
                            onClick = {
                                viewModel.startStopModulating()
                            })
                        Spacer(modifier = Modifier.width(20.dp))
                        if (uiState.bandPowerSnapshot != null)
                            Text(
                                text = "%.1f".format(uiState.bandPowerSnapshot),
                                style = MaterialTheme.typography.labelLarge,
                                modifier = Modifier.align(Alignment.CenterVertically)
                        )
                    }
                    Spacer(modifier = Modifier.height(20.dp))
                    Row {
                        if (uiState.modulationSuccess)
                            Text(
                                text = "SUCCESS",
                                style = MaterialTheme.typography.labelLarge.copy(
                                    color = BudzColor.green
                                ),
                                modifier = Modifier.align(Alignment.CenterVertically)
                            )
                    }
                }
            }
        }
    }
}