package io.nextsense.android.airoha.device

class GetBatteryRaceCommand : NextSenseRaceCommand(
    raceCommandType = RaceCommandType.NEEDS_RESPONSE,
    raceId = RaceId.AFE,
    nextSenseCommandType = NextSenseCommandType.SEND,
    nextSenseId = "05"
) {
    override fun getName(): String {
        return GetBatteryRaceCommand::class.java.simpleName
    }

    override fun getBytes(): ByteArray {
        return super.getBytes(ByteArray(0))
    }
}