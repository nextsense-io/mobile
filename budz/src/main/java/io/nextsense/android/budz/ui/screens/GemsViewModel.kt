package io.nextsense.android.budz.ui.screens

import android.content.Context
import android.util.Log
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import io.nextsense.android.algo.signal.BandPowerAnalysis
import io.nextsense.android.budz.manager.AchievementManager
import io.nextsense.android.budz.manager.AirohaDeviceManager
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
    val bandPowersList: List<Map<BandPowerAnalysis.Band, Float>> = emptyList()
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
        val closestGem = AchievementManager.getClosestGem(
            _uiState.value.bandPowersList.last()
        )
        Log.d(tag, "closestGem: ${closestGem.label}")
        _uiState.value = _uiState.value.copy(testStarted = false, closestGem = closestGem)
    }

    private fun updateBandPowers() {
        val bandPowers = signalStateManager.getBandPowers(listOf(BandPowerAnalysis.Band.DELTA,
            BandPowerAnalysis.Band.THETA, BandPowerAnalysis.Band.ALPHA, BandPowerAnalysis.Band.BETA,
            BandPowerAnalysis.Band.GAMMA))
        val rightBandPowers = bandPowers[1] ?: return
        val multiplyFactor = (1 / (rightBandPowers[BandPowerAnalysis.Band.ALPHA]!! +
                rightBandPowers[BandPowerAnalysis.Band.THETA]!! +
                rightBandPowers[BandPowerAnalysis.Band.BETA]!!)) * 100
        _uiState.value = _uiState.value.copy(
            bandPowersList = _uiState.value.bandPowersList.plus(
                mapOf(
                    BandPowerAnalysis.Band.THETA to (rightBandPowers[BandPowerAnalysis.Band.THETA]!!
                            * multiplyFactor).toFloat(),
                    BandPowerAnalysis.Band.ALPHA to (rightBandPowers[BandPowerAnalysis.Band.ALPHA]!!
                            * multiplyFactor).toFloat(),
                    BandPowerAnalysis.Band.BETA to (rightBandPowers[BandPowerAnalysis.Band.BETA]!!
                            * multiplyFactor).toFloat(),
                )
            )
        )
    }
}