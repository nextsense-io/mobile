package io.nextsense.android.airoha.device

class VoicePromptsControlsRaceResponse(nextSensePayload: ByteArray) : NextSenseRaceResponse(
    raceCommandType = RaceCommandType.NOTIFICATION,
    raceId = RaceId.AFE,
    nextSenseCommandType = NextSenseRaceCommand.NextSenseCommandType.NOTIFY,
    nextSenseId = NextSenseRaceCommand.NextSenseId.DISABLE_VOICE_PROMPTS,
    data = nextSensePayload
) {
    fun isDisabled(): Boolean {
        return getPayload()[0].toInt() == 1
    }
}