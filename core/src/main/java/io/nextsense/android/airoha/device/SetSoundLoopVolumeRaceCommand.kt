package io.nextsense.android.airoha.device

import com.airoha.libutils.Converter

class SetSoundLoopVolumeRaceCommand(volume: Int) : NextSenseRaceCommand(
    raceCommandType = RaceCommandType.NEEDS_RESPONSE,
    raceId = RaceId.AFE,
    nextSenseCommandType = NextSenseCommandType.NOTIFY,
    nextSenseId = "04"
) {
    companion object {
        const val MIN_VOLUME = 0
        const val MAX_VOLUME = 4
    }

    private val _volume: Int = volume

    override fun getBytes(): ByteArray {
        val effectiveVolume = if (_volume < MIN_VOLUME) MIN_VOLUME else
            if (_volume > MAX_VOLUME) MAX_VOLUME else _volume
        return super.getBytes(payload = Converter.hexStringToByteArray("0$effectiveVolume"))
    }
}