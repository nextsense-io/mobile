package io.nextsense.android.airoha.device

class GetBatteryRaceResponse(nextSensePayload: ByteArray) : NextSenseRaceResponse(
    raceCommandType = RaceCommandType.NOTIFICATION,
    raceId = RaceId.AFE,
    nextSenseCommandType = NextSenseRaceCommand.NextSenseCommandType.NOTIFY,
    nextSenseId = NextSenseRaceCommand.NextSenseId.BATTERY_LEVEL,
    data = nextSensePayload
) {
    companion object {
        const val BATTERY_NOT_AVAILABLE = -1
    }

    fun getLeftEarPercent(): Int? {
        val leftEarBattery = getPayload()[0].toInt()
        if (leftEarBattery == BATTERY_NOT_AVAILABLE) {
            return null
        }
        return leftEarBattery
    }

    fun getRightEarPercent(): Int? {
        val rightEarBattery = getPayload()[1].toInt()
        if (rightEarBattery == BATTERY_NOT_AVAILABLE) {
            return null
        }
        return rightEarBattery
    }

    fun getCasePercent(): Int? {
        val caseBattery = getPayload()[2].toInt()
        if (caseBattery == BATTERY_NOT_AVAILABLE) {
            return null
        }
        return caseBattery
    }
}