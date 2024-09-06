package io.nextsense.android.airoha.device

import com.airoha.sdk.api.utils.AirohaStatusCode
import io.nextsense.android.airoha.device.NextSenseRaceCommand.NextSenseCommandType

open class NextSenseRaceResponse(
        raceCommandType: RaceCommandType, raceId: RaceId,
        nextSenseCommandType: NextSenseCommandType, nextSenseId: NextSenseRaceCommand.NextSenseId,
        data: ByteArray) :
    RaceResponse(raceCommandType = raceCommandType, raceId = raceId, data = data) {

    private val _nextSenseCommandType: NextSenseCommandType = nextSenseCommandType
    private val _nextSenseId: NextSenseRaceCommand.NextSenseId = nextSenseId
    private val _data: ByteArray = data

    override fun getPayload(): ByteArray {
        return _data.copyOfRange(0, _data.size - 1)
    }

    @OptIn(ExperimentalStdlibApi::class)
    override fun getStatusCode(): AirohaStatusCode {
        // Last byte contains the Airoha status code.
        return AirohaStatusCode.valueOf(_data[_data.size - 1].toHexString())
    }
}