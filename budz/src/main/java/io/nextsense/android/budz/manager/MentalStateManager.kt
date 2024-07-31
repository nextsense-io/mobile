package io.nextsense.android.budz.manager

import io.nextsense.android.algo.signal.BandPowerAnalysis
import io.nextsense.android.algo.signal.BandPowerAnalysis.Band
import io.nextsense.android.base.devices.maui.MauiDataParser
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.time.Duration.Companion.seconds

@Singleton
class MentalStateManager @Inject constructor(val airohaDeviceManager: AirohaDeviceManager) {
    private val defaultCalculationEpoch = 36.seconds
    private var _bandPowers: MutableMap<Band, Double> = mutableMapOf()
    private val _calculationEpoch = defaultCalculationEpoch

    fun getBandPowers(bands: List<Band>): Map<Band, Double> {
        if (bands.isEmpty()) {
            return mapOf()
        }
        var data = airohaDeviceManager.getChannelData(localSessionId=null,
            channelName = MauiDataParser.CHANNEL_LEFT.toString(),
            durationMillis = _calculationEpoch.inWholeMilliseconds.toInt(), fromDatabase = false)
        if (data?.isEmpty() == true) {
            data = airohaDeviceManager.getChannelData(localSessionId=null,
                channelName = MauiDataParser.CHANNEL_RIGHT.toString(),
                durationMillis = _calculationEpoch.inWholeMilliseconds.toInt(),
                fromDatabase = false)
        }
        if (data?.isEmpty() == true) {
            return mapOf()
        }
        bands.forEach { band ->
            _bandPowers[band] = BandPowerAnalysis.getBandPower(data, 1000, band, 60.0)
        }
        return _bandPowers
    }
}