package io.nextsense.android.budz.manager

import io.nextsense.android.algo.signal.BandPowerAnalysis
import io.nextsense.android.algo.signal.BandPowerAnalysis.Band
import io.nextsense.android.algo.signal.Filters
import io.nextsense.android.algo.signal.Sampling
import io.nextsense.android.algo.signal.WaveletArtifactRejection
import io.nextsense.android.base.devices.maui.MauiDataParser
import io.nextsense.android.base.utils.RotatingFileLogger
import kotlinx.coroutines.flow.MutableStateFlow
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.math.abs
import kotlin.time.Duration.Companion.seconds

@Singleton
class SignalStateManager @Inject constructor(val airohaDeviceManager: AirohaDeviceManager) {
    private val tag = SignalStateManager::class.simpleName
    private val defaultCalculationEpoch = 17.seconds
    private val _bandPowers: MutableMap<Int, MutableMap<Band, Double>> = mutableMapOf()
    private val _calculationEpoch = defaultCalculationEpoch
    private var _powerLineFrequency: Int? = null

    val bandPowersState = MutableStateFlow(_bandPowers)

    val powerLineFrequency: Int?
        get() = _powerLineFrequency

    fun getBandPowers(bands: List<Band>): Map<Int, MutableMap<Band, Double>> {
        if (bands.isEmpty()) {
            return mapOf()
        }
        val newBandPowers: MutableMap<Int, MutableMap<Band, Double>> = mutableMapOf()
        for (channel in arrayOf(MauiDataParser.CHANNEL_LEFT, MauiDataParser.CHANNEL_RIGHT)) {
            val data = airohaDeviceManager.getChannelData(
                localSessionId = null,
                channelName = channel.toString(),
                durationMillis = _calculationEpoch.inWholeMilliseconds.toInt(), fromDatabase = false
            )
            if (data?.isEmpty() == true) {
                continue
            }
            val eegSamplingRate = airohaDeviceManager.getEegSamplingRate().toInt()
            val powerLineFrequency = getPowerLineFrequency(data, eegSamplingRate) ?: return mapOf()
            newBandPowers[channel] = BandPowerAnalysis.getBandPowersBF(
                data, eegSamplingRate, bands,
                powerLineFrequency.toDouble()
            )
        }
        bandPowersState.value = newBandPowers
        return newBandPowers
    }

    fun prepareVisualizedData(data: List<Float>, filtered: Boolean, removeArtifacts: Boolean,
                              targetSamplingRate: Float): List<Double> {
        val powerLineFrequency = getPowerLineFrequency(
            data, airohaDeviceManager.getEegSamplingRate().toInt())
        var doubleData = data.map { it.toDouble() }.toDoubleArray()
        if (removeArtifacts) {
            doubleData = WaveletArtifactRejection.getPowerOf2DataSize(doubleData)
            doubleData = WaveletArtifactRejection.applyWaveletArtifactRejection(doubleData)
        }
        if (filtered) {
            if (powerLineFrequency != null) {
                Filters.removeEnvironmentalNoise(
                    doubleData, airohaDeviceManager.getEegSamplingRate(), powerLineFrequency)
            }
            Filters.applyBandPassBF(doubleData, airohaDeviceManager.getEegSamplingRate(),
                /*order=*/4, /*lowCutoff=*/0.3F, /*highCutoff=*/90F)
        }
        // Resample the data to the chart sampling rate for performance.
        return Sampling.downsampleBF(doubleData, airohaDeviceManager.getEegSamplingRate(),
            targetSamplingRate).toList()
    }

    private fun getPowerLineFrequency(data: List<Float>?, eegSamplingRate: Int): Int? {
        if (_powerLineFrequency == null && !isSignalFlat(data, windows = 4)) {
            _powerLineFrequency = findPowerLineFrequency(data, eegSamplingRate)
        }
        if (_powerLineFrequency == null) {
            return null
        }
        return _powerLineFrequency
    }

    private fun findPowerLineFrequency(data: List<Float>?, eegSamplingRate: Int): Int? {
        val fiftyHertzBandPower = BandPowerAnalysis.getBandPower(data, eegSamplingRate,
            /*bandStart=*/49.0, /*bandEnd=*/51.0, /*powerLineFrequency=*/null)
        val sixtyHertzBandPower = BandPowerAnalysis.getBandPower(data, eegSamplingRate,
            /*bandStart=*/59.0, /*bandEnd=*/61.0, /*powerLineFrequency=*/null)
        RotatingFileLogger.get().logi(tag, "50 hertz band power: $fiftyHertzBandPower\n" +
                "60 hertz band power: $sixtyHertzBandPower")
        if (fiftyHertzBandPower == 0.0 && sixtyHertzBandPower == 0.0) {
            return null
        }
        return if (fiftyHertzBandPower > sixtyHertzBandPower) 60 else 60
    }

    private fun isSignalFlat(data: List<Float>?, windows: Int = 1): Boolean {
        if (data == null) {
            return false
        }
        val threshold = 1.0
        for (i in data.indices step data.size / windows) {
            if (isWindowFlat(data.subList(i, (i + data.size / windows).coerceAtMost(data.size)),
                    threshold)) {
                return true
            }
        }
        return false
    }

    private fun isWindowFlat(data: List<Float>, threshold: Double): Boolean {
        val max = data.maxOrNull() ?: return false
        val min = data.minOrNull() ?: return false
        return abs(abs(max) - abs(min)) < threshold
    }
}