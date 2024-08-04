package io.nextsense.android.airoha.device

import com.airoha.libutils.Converter

class GetAfeRegisterRaceCommand(register: String) : NextSenseRaceCommand(
    raceCommandType = RaceCommandType.NEEDS_RESPONSE,
    raceId = RaceId.AFE,
    nextSenseCommandType = NextSenseCommandType.SEND,
    nextSenseId = "00"
) {
    private val _register: String = register

    override fun getBytes(): ByteArray {
        return super.getBytes(payload = Converter.hexStringToByteArray(_register))
    }
}