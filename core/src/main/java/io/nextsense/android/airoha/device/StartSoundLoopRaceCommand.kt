package io.nextsense.android.airoha.device

import com.airoha.libutils.Converter

class StartStopSoundLoopRaceCommand(soundLoopType: SoundLoopType) : NextSenseRaceCommand(
    raceCommandType = RaceCommandType.NEEDS_RESPONSE,
    raceId = RaceId.AFE,
    nextSenseCommandType = NextSenseCommandType.SEND,
    nextSenseId = "03"
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

    private val _soundLoopType: SoundLoopType = soundLoopType

    override fun getBytes(): ByteArray {
        return super.getBytes(payload = _soundLoopType.getHexValue())
    }
}