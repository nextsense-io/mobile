package io.nextsense.android.airoha.device

import com.airoha.libutils.Converter

class SetAfeRegisterRaceCommand(register: String, value: String) : NextSenseRaceCommand(
    raceCommandType = RaceCommandType.NEEDS_RESPONSE,
    raceId = RaceId.AFE,
    nextSenseCommandType = NextSenseCommandType.SEND,
    nextSenseId = "01"
) {
    private val _register: String = register
    private val _value: String = value

    override fun getBytes(): ByteArray {
        return super.getBytes(payload = Converter.hexStringToByteArray(_register) +
                Converter.hexStringToByteArray(_value))
    }
}