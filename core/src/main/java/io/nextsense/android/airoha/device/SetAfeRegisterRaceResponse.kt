package io.nextsense.android.airoha.device

import io.nextsense.android.airoha.device.NextSenseRaceCommand.NextSenseCommandType

class SetAfeRegisterRaceResponse(nextSensePayload: ByteArray) : NextSenseRaceResponse(
    raceCommandType = RaceCommandType.NOTIFICATION,
    raceId = RaceId.AFE,
    nextSenseCommandType = NextSenseRaceCommand.NextSenseCommandType.NOTIFY,
    nextSenseId = NextSenseRaceCommand.NextSenseId.WRITE_AFE_REG,
    data = nextSensePayload
) {
    fun getRegister() : Byte {
        return getPayload()[0]
    }
}