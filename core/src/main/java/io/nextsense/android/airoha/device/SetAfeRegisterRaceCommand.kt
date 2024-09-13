package io.nextsense.android.airoha.device

import com.airoha.libutils.Converter

class SetAfeRegisterRaceCommand(
    private val earbudSide: EarbudSide, private val register: String,
    private val value: String) : NextSenseRaceCommand(
    raceCommandType = RaceCommandType.NEEDS_RESPONSE,
    raceId = RaceId.AFE,
    nextSenseCommandType = NextSenseCommandType.SEND,
    nextSenseId = "01"
) {
    enum class EarbudSide(val value: String) {
        LEFT("00"),
        RIGHT("01");

        companion object {
            fun valueOf(value: Byte): EarbudSide {
                return when (value) {
                    0.toByte() -> LEFT
                    1.toByte() -> RIGHT
                    else -> throw IllegalArgumentException("Invalid value: $value")
                }
            }
        }
    }

    override fun getName(): String {
        return SetAfeRegisterRaceCommand::class.java.simpleName
    }

    override fun getBytes(): ByteArray {
        return super.getBytes(payload = Converter.hexStringToByteArray(earbudSide.value) +
            Converter.hexStringToByteArray(register) +
            Converter.hexStringToByteArray(value))
    }
}