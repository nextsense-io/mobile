package io.nextsense.android.airoha.device

import com.airoha.sdk.api.utils.AirohaStatusCode

open class RaceResponse(
    val raceCommandType: RaceCommandType, val raceId: RaceId, val data: ByteArray) :
    RaceCommand(
        raceCommandType = raceCommandType,
        raceId = raceId
) {
    override fun getBytes(): ByteArray {
        return data
    }

    protected open fun getPayload(): ByteArray {
        return data.copyOfRange(0, data.size - 1)
    }

    @OptIn(ExperimentalStdlibApi::class)
    open fun getStatusCode(): AirohaStatusCode {
        // Last byte contains the Airoha status code.
        return AirohaStatusCode.valueOf(data[data.size - 1].toHexString())
    }
}