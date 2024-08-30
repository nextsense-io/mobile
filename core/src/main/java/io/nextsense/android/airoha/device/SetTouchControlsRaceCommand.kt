package io.nextsense.android.airoha.device

import com.airoha.libutils.Converter

class SetTouchControlsRaceCommand(disable: Boolean) : NextSenseRaceCommand(
    raceCommandType = RaceCommandType.NEEDS_RESPONSE,
    raceId = RaceId.AFE,
    nextSenseCommandType = NextSenseCommandType.NOTIFY,
    nextSenseId = "07"
) {
    private val _disable: Boolean = disable

    override fun getName(): String {
        return SetTouchControlsRaceCommand::class.java.simpleName
    }

    override fun getBytes(): ByteArray {
        return super.getBytes(payload = Converter.intToBytes(if (_disable) 1 else 0))
    }
}