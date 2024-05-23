package io.nextsense.android.airoha.device

import com.airoha.libutils.Converter

abstract class RaceCommand(raceCommandType: RaceCommandType, raceId: RaceId) {

    enum class RaceCommandType(private val value: String) {
        NEEDS_RESPONSE("5A"),
        RESPONSE("5B"),
        NO_RESPONSE("5C"),
        NOTIFICATION("5D");

        fun getValue(): String {
            return value
        }

        fun getHexValue(): ByteArray {
            return Converter.hexStringToByteArray(value)
        }

    }

    enum class RaceId(private val value: String) {
        AFE("0100");

        fun getValue(): String {
            return value
        }

        fun getHexValue(): ByteArray {
            return Converter.hexStringToByteArray(value)
        }
    }

    private val _channel = Converter.hexStringToByteArray("05")
    // 2 bytes for the race ID. Characters before the length field are not counted.
    private val _baseLength: Short = 2
    private val _raceCommandType: RaceCommandType = raceCommandType
    private val _raceId: RaceId = raceId

    protected open fun getBytes(payload: ByteArray): ByteArray {
        val length = (_baseLength + payload.size).toShort()
        return _channel + _raceCommandType.getHexValue() + Converter.shortToBytes(length) +
            _raceId.getHexValue() + payload
    }

    abstract fun getBytes(): ByteArray
}