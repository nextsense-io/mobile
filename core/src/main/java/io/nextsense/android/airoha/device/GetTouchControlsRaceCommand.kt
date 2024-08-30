package io.nextsense.android.airoha.device

class GetTouchControlsRaceCommand() : NextSenseRaceCommand(
    raceCommandType = RaceCommandType.NEEDS_RESPONSE,
    raceId = RaceId.AFE,
    nextSenseCommandType = NextSenseCommandType.SEND,
    nextSenseId = "07"
) {
    override fun getName(): String {
        return GetTouchControlsRaceCommand::class.java.simpleName
    }

    override fun getBytes(): ByteArray {
        return super.getBytes(ByteArray(0))
    }
}