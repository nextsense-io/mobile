package io.nextsense.android.budz.ui.screens

import android.content.Context
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import io.nextsense.android.algo.signal.BandPowerAnalysis
import io.nextsense.android.base.devices.maui.MauiDevice
import io.nextsense.android.base.utils.RotatingFileLogger
import io.nextsense.android.budz.manager.AchievementManager
import io.nextsense.android.budz.manager.AirohaDeviceManager
import io.nextsense.android.budz.manager.EarEegChannel
import io.nextsense.android.budz.manager.EarbudsConfigNames
import io.nextsense.android.budz.manager.EarbudsConfigs
import io.nextsense.android.budz.manager.Gem
import io.nextsense.android.budz.manager.SignalStateManager
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject
import kotlin.time.Duration.Companion.seconds

data class GemsState(
    val connected: Boolean = false,
    val testStarted: Boolean = false,
    val closestGem: Gem? = null,
    val bandPowersList: List<Map<BandPowerAnalysis.Band, Float>> = emptyList(),
    val activeChannel: EarEegChannel = EarbudsConfigs.getEarbudsConfig(
        EarbudsConfigNames.MAUI_CONFIG.name).channelsConfig[1]!!,
)

@HiltViewModel
class GemsViewModel @Inject constructor(
    @ApplicationContext private val context: Context,
    val airohaDeviceManager: AirohaDeviceManager,
    val signalStateManager: SignalStateManager,
): SignalVisualizationViewModel(context, airohaDeviceManager, signalStateManager) {
    private val tag = GemsViewModel::class.simpleName
    private val _uiState = MutableStateFlow(GemsState())
    private val _bandPowersCheckInterval = 5.seconds
    private val _bandPowersCheckDuration = 31.seconds
    private var _bandPowersCheckJob: Job? = null
    private var _bandPowersCheckDurationJob: Job? = null

    val uiState: StateFlow<GemsState> = _uiState.asStateFlow()

    init {
        setUpdateSignalGraph(false)
    }

    fun startStopTest() {
        if (_uiState.value.testStarted) {
            stopCheckingBandPowers()
        } else {
            startCheckingBandPowers()
        }
    }

    fun changeActiveChannel(activeChannel: EarEegChannel) {
        _uiState.value = _uiState.value.copy(activeChannel = activeChannel)
    }

    fun getChannels(): List<String> {
        return EarbudsConfigs.getEarbudsConfig(MauiDevice.EARBUD_CONFIG).channelsConfig.values
            .map { it.alias }
    }

    private fun startCheckingBandPowers() {
        _uiState.value = _uiState.value.copy(testStarted = true, bandPowersList = emptyList(),
            closestGem = null)
        _bandPowersCheckJob = viewModelScope.launch {
            while (true) {
                updateBandPowers()
                delay(_bandPowersCheckInterval.inWholeMilliseconds)
            }
        }
        _bandPowersCheckDurationJob = viewModelScope.launch {
            delay(_bandPowersCheckDuration.inWholeMilliseconds)
            stopCheckingBandPowers()
        }
    }

    fun stopCheckingBandPowers() {
        _bandPowersCheckDurationJob?.cancel()
        _bandPowersCheckJob?.cancel()
        var closestGem: Gem? = null
        if (_uiState.value.bandPowersList.isNotEmpty()) {
            closestGem = AchievementManager.getClosestGem(
                _uiState.value.bandPowersList.last()
            )
            RotatingFileLogger.get().logd(tag, "closestGem: ${closestGem.label}")
        }
        _uiState.value = _uiState.value.copy(testStarted = false, closestGem = closestGem)
    }

    private fun updateBandPowers() {
        val bandPowers = signalStateManager.getBandPowers(listOf(BandPowerAnalysis.Band.DELTA,
            BandPowerAnalysis.Band.THETA, BandPowerAnalysis.Band.ALPHA, BandPowerAnalysis.Band.BETA,
            BandPowerAnalysis.Band.GAMMA))
        val channel = if (uiState.value.activeChannel == EarEegChannel.ELW_ELC) {
            1
        } else {
            2
        }
        val channelBandPowers = bandPowers[channel] ?: return
        RotatingFileLogger.get().logd(tag, "${uiState.value.activeChannel.alias} band powers: " +
                "$channelBandPowers")
        val multiplyFactor = (1 / (channelBandPowers[BandPowerAnalysis.Band.ALPHA]!! +
                channelBandPowers[BandPowerAnalysis.Band.THETA]!! +
                channelBandPowers[BandPowerAnalysis.Band.BETA]!! +
                channelBandPowers[BandPowerAnalysis.Band.GAMMA]!!)) * 100
        _uiState.value = _uiState.value.copy(
            bandPowersList = _uiState.value.bandPowersList.plus(
                mapOf(
                    BandPowerAnalysis.Band.THETA to (channelBandPowers[BandPowerAnalysis.Band.THETA]!!
                            * multiplyFactor).toFloat(),
                    BandPowerAnalysis.Band.ALPHA to (channelBandPowers[BandPowerAnalysis.Band.ALPHA]!!
                            * multiplyFactor).toFloat(),
                    BandPowerAnalysis.Band.BETA to (channelBandPowers[BandPowerAnalysis.Band.BETA]!!
                            * multiplyFactor).toFloat(),
                    BandPowerAnalysis.Band.GAMMA to (channelBandPowers[BandPowerAnalysis.Band.GAMMA]!!
                            * multiplyFactor).toFloat(),
                )
            )
        )
    }
}