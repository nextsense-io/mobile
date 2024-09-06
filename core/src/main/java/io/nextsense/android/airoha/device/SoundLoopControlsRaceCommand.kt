package io.nextsense.android.airoha.device

import com.airoha.libutils.Converter

class SoundLoopControlsRaceCommand(
    private val soundLoopType: SoundLoopType, private val soundLoopId: Int,
    private val mixSounds: Boolean, private val mixLengthSeconds: Int) :
    NextSenseRaceCommand(raceCommandType = RaceCommandType.NEEDS_RESPONSE,
        raceId = RaceId.AFE, nextSenseCommandType = NextSenseCommandType.NOTIFY,
        nextSenseId = "08"
) {
    enum class SoundLoopType(private val value: String) {
        START_LOOP("01"),
        STOP_LOOP("00");

        fun getHexValue(): ByteArray {
            return Converter.hexStringToByteArray(value)
        }
    }

    override fun getName(): String {
        return StartStopSoundLoopRaceCommand::class.java.simpleName
    }

    override fun getBytes(): ByteArray {
        return super.getBytes(payload = soundLoopType.getHexValue() +
            Converter.hexStringToByteArray(soundLoopId.toString(16).padStart(2, '0')) +
            Converter.hexStringToByteArray(if (mixSounds) "01" else "00") +
            Converter.hexStringToByteArray(mixLengthSeconds.toString(16).padStart(2, '0')))
    }
}