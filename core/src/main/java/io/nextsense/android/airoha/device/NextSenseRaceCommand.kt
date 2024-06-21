package io.nextsense.android.airoha.device

import com.airoha.libutils.Converter

abstract class NextSenseRaceCommand(
    raceCommandType: RaceCommandType,
    raceId: RaceId,
    nextSenseCommandType: NextSenseCommandType,
    nextSenseId: String
) : RaceCommand(raceCommandType, raceId) {

    enum class NextSenseCommandType(private val value: String) {
        SEND("05"),
        NOTIFY("03");

        fun get(): String {
            return value
        }

        fun getHexValue(): ByteArray {
            return Converter.hexStringToByteArray(value)
        }
    }

    private val _nextSenseCommandType: NextSenseCommandType = nextSenseCommandType
    private val _nextSenseId: String = nextSenseId

    override fun getBytes(payload: ByteArray): ByteArray {
        val nextSensePayload = _nextSenseCommandType.getHexValue() +
                Converter.hexStringToByteArray(_nextSenseId)
        return super.getBytes(payload = nextSensePayload + payload)
    }
}