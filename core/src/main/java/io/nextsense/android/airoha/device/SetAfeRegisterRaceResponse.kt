package io.nextsense.android.airoha.device

class SetAfeRegisterRaceResponse(nextSensePayload: ByteArray) : NextSenseRaceResponse(
    raceCommandType = RaceCommandType.NOTIFICATION,
    raceId = RaceId.AFE,
    nextSenseCommandType = NextSenseRaceCommand.NextSenseCommandType.NOTIFY,
    nextSenseId = NextSenseRaceCommand.NextSenseId.WRITE_AFE_REG,
    data = nextSensePayload
) {
    fun getEarbudSide() : SetAfeRegisterRaceCommand.EarbudSide {
        return SetAfeRegisterRaceCommand.EarbudSide.valueOf(getPayload()[0])
    }

    fun getRegister() : Byte {
        return getPayload()[1]
    }
}