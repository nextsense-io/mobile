package io.nextsense.android.airoha.device

import com.airoha.libutils.Converter

class PowerRaceCommand(powerType: PowerType) : RaceCommand(
    raceCommandType = RaceCommandType.NEEDS_RESPONSE,
    raceId = RaceId.MCU
) {

    enum class PowerType(private val value: String) {
        POWER_OFF("18"),
        RESET("19");

        fun getHexValue(): ByteArray {
            return Converter.hexStringToByteArray(value)
        }
    }

    private val _powerType: PowerType = powerType

    override fun getBytes(): ByteArray {
        return super.getBytes(payload = _powerType.getHexValue() + byteArrayOf(0x00))
    }
}