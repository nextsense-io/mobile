package io.nextsense.android.airoha.device

import com.airoha.libutils.Converter

class DataStreamRaceCommand(dataStreamType: DataStreamType) : NextSenseRaceCommand(
    raceCommandType = RaceCommandType.NEEDS_RESPONSE,
    raceId = RaceId.AFE,
    nextSenseCommandType = NextSenseCommandType.SEND,
    nextSenseId = "02"
) {

    enum class DataStreamType(private val value: String) {
        START_STREAM("01"),
        STOP_STREAM("00");

        fun getHexValue(): ByteArray {
            return Converter.hexStringToByteArray(value)
        }
    }

    private val _dataStreamType: DataStreamType = dataStreamType

    override fun getBytes(): ByteArray {
        return super.getBytes(payload = _dataStreamType.getHexValue())
    }
}