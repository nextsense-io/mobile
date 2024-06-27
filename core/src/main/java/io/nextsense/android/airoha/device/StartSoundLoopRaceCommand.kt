package io.nextsense.android.airoha.device

class StartStopSoundLoopRaceCommand : NextSenseRaceCommand(
    raceCommandType = RaceCommandType.NEEDS_RESPONSE,
    raceId = RaceId.MCU,
    nextSenseCommandType = NextSenseCommandType.NOTIFY,
    nextSenseId = "F0"
) {
    override fun getBytes(): ByteArray {
        return super.getBytes(payload = ByteArray(0))
    }
}