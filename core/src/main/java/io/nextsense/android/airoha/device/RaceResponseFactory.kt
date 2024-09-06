package io.nextsense.android.airoha.device

import com.airoha.libutils.Converter
import io.nextsense.android.base.utils.RotatingFileLogger
import java.nio.ByteBuffer
import java.nio.ByteOrder

class RaceResponseFactory {

    companion object {
        private const val TAG = "RaceResponseFactory"
        private const val BASE_DATA_LENGTH = 4
        private const val COMMON_NEXTSENSE_DATA_LENGTH = 8
        private const val COMMON_DATA_LENGTH = 6
        private const val RACE_CHANNEL = 5

        fun create(dataBytes: ByteArray): RaceResponse? {
            val dataBytebuffer = ByteBuffer.wrap(dataBytes)
            dataBytebuffer.order(ByteOrder.LITTLE_ENDIAN)
            val channel = dataBytebuffer.get().toInt()
            if (channel != RACE_CHANNEL) {
                RotatingFileLogger.get().logw(TAG, "Invalid channel: $channel, might not be a " +
                        "RACE response.")
                return null
            }
            val raceCommandType =
                RaceCommand.RaceCommandType.fromValue(dataBytebuffer.get())
            val length = dataBytebuffer.getShort()
            val raceIdString = Converter.byteArrayToHexString(
                byteArrayOf(dataBytebuffer.get(), dataBytebuffer.get()))
            when (val raceId = RaceCommand.RaceId.fromValue(raceIdString)) {
                RaceCommand.RaceId.MCU -> {
                    val payloadLength = length + BASE_DATA_LENGTH - COMMON_DATA_LENGTH
                    val payload = ByteArray(payloadLength)
                    dataBytebuffer.get(payload, /*offset=*/0, payloadLength)

                    return RaceResponse(raceCommandType = raceCommandType,
                        raceId = raceId, data = payload)
                }
                RaceCommand.RaceId.AFE -> {
                    val nextSenseCommandType =
                        NextSenseRaceCommand.NextSenseCommandType.fromValue(dataBytebuffer.get())
                    if (nextSenseCommandType != NextSenseRaceCommand.NextSenseCommandType.NOTIFY) {
                        RotatingFileLogger.get().logw(
                            TAG, "Unexpected NextSenseCommandType: $nextSenseCommandType"
                        )
                        return null
                    }

                    val nextSenseId =
                        NextSenseRaceCommand.NextSenseId.fromValue(dataBytebuffer.get())
                    val payloadLength = length + BASE_DATA_LENGTH - COMMON_NEXTSENSE_DATA_LENGTH
                    val payload = ByteArray(payloadLength)
                    dataBytebuffer.get(payload, /*offset=*/0, payloadLength)

                    when (nextSenseId) {
                        NextSenseRaceCommand.NextSenseId.READ_AFE_REG ->
                            return GetAfeRegisterRaceResponse(nextSensePayload = payload)
                        NextSenseRaceCommand.NextSenseId.WRITE_AFE_REG ->
                            return SetAfeRegisterRaceResponse(nextSensePayload = payload)
                        NextSenseRaceCommand.NextSenseId.DATA_STREAM,
                        NextSenseRaceCommand.NextSenseId.SOUND_LOOP_PLAY ->
                            return NextSenseRaceResponse(raceCommandType = raceCommandType,
                                raceId = raceId, nextSenseCommandType = nextSenseCommandType,
                                nextSenseId = nextSenseId, data = payload)
                        NextSenseRaceCommand.NextSenseId.SOUND_LOOP_VOLUME ->
                            return SoundLoopVolumeRaceResponse(nextSensePayload = payload)
                        NextSenseRaceCommand.NextSenseId.BATTERY_LEVEL -> TODO()
                        NextSenseRaceCommand.NextSenseId.DISABLE_VOICE_PROMPTS ->
                            return VoicePromptsControlsRaceResponse(nextSensePayload = payload)
                        NextSenseRaceCommand.NextSenseId.DISABLE_TOUCH_CONTROLS ->
                            return TouchControlsRaceResponse(nextSensePayload = payload)
                        NextSenseRaceCommand.NextSenseId.SOUND_LOOP_CONTROLS ->
                            return SoundLoopControlsRaceResponse(nextSensePayload = payload)
                        else -> {
                            RotatingFileLogger.get().logw(TAG, "Unknown NextSenseId: $nextSenseId")
                            return null
                        }
                    }
                }
            }
        }
    }
}