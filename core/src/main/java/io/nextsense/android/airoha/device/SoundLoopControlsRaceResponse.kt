package io.nextsense.android.airoha.device

class SoundLoopControlsRaceResponse(nextSensePayload: ByteArray) : NextSenseRaceResponse(
    raceCommandType = RaceCommandType.NOTIFICATION,
    raceId = RaceId.AFE,
    nextSenseCommandType = NextSenseRaceCommand.NextSenseCommandType.NOTIFY,
    nextSenseId = NextSenseRaceCommand.NextSenseId.SOUND_LOOP_CONTROLS,
    data = nextSensePayload
) {
    fun getSoundId(): Int {
        return getPayload()[0].toInt()
    }
}