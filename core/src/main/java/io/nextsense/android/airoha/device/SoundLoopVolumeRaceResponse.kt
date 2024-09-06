package io.nextsense.android.airoha.device

class SoundLoopVolumeRaceResponse(nextSensePayload: ByteArray) : NextSenseRaceResponse(
    raceCommandType = RaceCommandType.NOTIFICATION,
    raceId = RaceId.AFE,
    nextSenseCommandType = NextSenseRaceCommand.NextSenseCommandType.NOTIFY,
    nextSenseId = NextSenseRaceCommand.NextSenseId.SOUND_LOOP_VOLUME,
    data = nextSensePayload
) {
    fun getVolume(): Int {
        return getPayload()[0].toInt()
    }
}