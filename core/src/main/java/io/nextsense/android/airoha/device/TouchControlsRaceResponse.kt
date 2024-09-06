package io.nextsense.android.airoha.device

class TouchControlsRaceResponse(nextSensePayload: ByteArray) : NextSenseRaceResponse(
    raceCommandType = RaceCommandType.NOTIFICATION,
    raceId = RaceId.AFE,
    nextSenseCommandType = NextSenseRaceCommand.NextSenseCommandType.NOTIFY,
    nextSenseId = NextSenseRaceCommand.NextSenseId.DISABLE_TOUCH_CONTROLS,
    data = nextSensePayload
) {
    fun isDisabled(): Boolean {
        return getPayload()[0].toInt() == 1
    }
}