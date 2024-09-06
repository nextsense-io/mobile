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

        companion object {
            @OptIn(ExperimentalStdlibApi::class)
            fun fromValue(byteValue: Byte): NextSenseCommandType {
                for (type in entries) {
                    if (type.value == byteValue.toHexString()) {
                        return type
                    }
                }
                throw IllegalArgumentException("Unknown NextSenseCommandType value: " +
                        byteValue.toHexString())
            }
        }
    }

    enum class NextSenseId(private val value: String) {
        READ_AFE_REG("00"),
        WRITE_AFE_REG("01"),
        DATA_STREAM("02"),
        SOUND_LOOP_PLAY("03"),  // Deprecated, use SOUND_LOOP_CONTROL instead.
        SOUND_LOOP_VOLUME("04"),
        BATTERY_LEVEL("05"),
        DISABLE_VOICE_PROMPTS("06"),
        DISABLE_TOUCH_CONTROLS("07"),
        SOUND_LOOP_CONTROLS("08");

        fun get(): String {
            return value
        }

        fun getHexValue(): ByteArray {
            return Converter.hexStringToByteArray(value)
        }

        companion object {
            @OptIn(ExperimentalStdlibApi::class)
            fun fromValue(byteValue: Byte): NextSenseId {
                for (nsId in entries) {
                    if (nsId.value == byteValue.toHexString()) {
                        return nsId
                    }
                }
                throw IllegalArgumentException("Unknown NextSenseId value: " +
                        byteValue.toHexString())
            }
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