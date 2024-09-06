package io.nextsense.android.airoha.device

class GetAfeRegisterRaceResponse(nextSensePayload: ByteArray) : NextSenseRaceResponse(
    raceCommandType = RaceCommandType.NOTIFICATION,
    raceId = RaceId.AFE,
    nextSenseCommandType = NextSenseRaceCommand.NextSenseCommandType.NOTIFY,
    nextSenseId = NextSenseRaceCommand.NextSenseId.READ_AFE_REG,
    data = nextSensePayload
) {
    fun getRegister(): Byte {
        return getPayload()[0]
    }

    fun getValue(): ByteArray {
        return getPayload().copyOfRange(1, getPayload().size)
    }
}