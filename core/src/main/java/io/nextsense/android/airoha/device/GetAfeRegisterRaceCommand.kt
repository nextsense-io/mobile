package io.nextsense.android.airoha.device

import com.airoha.libutils.Converter

class GetAfeRegisterRaceCommand(
    private val earbudSide: SetAfeRegisterRaceCommand.EarbudSide,
    private val register: String) : NextSenseRaceCommand(
    raceCommandType = RaceCommandType.NEEDS_RESPONSE,
    raceId = RaceId.AFE,
    nextSenseCommandType = NextSenseCommandType.SEND,
    nextSenseId = "00"
) {
    override fun getName(): String {
        return GetAfeRegisterRaceCommand::class.java.simpleName
    }

    override fun getBytes(): ByteArray {
        return super.getBytes(payload = Converter.hexStringToByteArray(earbudSide.value) +
                Converter.hexStringToByteArray(register))
    }
}