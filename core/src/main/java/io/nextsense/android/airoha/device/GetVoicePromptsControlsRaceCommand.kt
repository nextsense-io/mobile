package io.nextsense.android.airoha.device

class GetVoicePromptsControlsRaceCommand() : NextSenseRaceCommand(
raceCommandType = RaceCommandType.NEEDS_RESPONSE,
raceId = RaceId.AFE,
nextSenseCommandType = NextSenseCommandType.SEND,
nextSenseId = "06"
) {
    override fun getName(): String {
        return GetVoicePromptsControlsRaceCommand::class.java.simpleName
    }

    override fun getBytes(): ByteArray {
        return super.getBytes(ByteArray(0))
    }
}