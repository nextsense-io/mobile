package io.nextsense.android.airoha.device

class GetSoundLoopVolumeRaceCommand : NextSenseRaceCommand(
    raceCommandType = RaceCommandType.NEEDS_RESPONSE,
    raceId = RaceId.AFE,
    nextSenseCommandType = NextSenseCommandType.SEND,
    nextSenseId = "04"
) {
    override fun getName(): String {
        return GetSoundLoopVolumeRaceCommand::class.java.simpleName
    }

    override fun getBytes(): ByteArray {
        return super.getBytes(ByteArray(0))
    }
}