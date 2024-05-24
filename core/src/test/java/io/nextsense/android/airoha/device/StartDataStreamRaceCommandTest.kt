package io.nextsense.android.airoha.device

import org.junit.Assert.assertArrayEquals
import org.junit.Test

class StartDataStreamRaceCommandTest {

    @Test
    fun testStartDataStreamRaceCommand() {
        val dataStreamRaceCommand = DataStreamRaceCommand(
            DataStreamRaceCommand.DataStreamType.START_STREAM)
        val bytes = dataStreamRaceCommand.getBytes()
        val expectedBytes = byteArrayOf(0x05, 0x5A, 0x05, 0x00, 0x01, 0x00, 0x05, 0x02, 0x01)
        assertArrayEquals(expectedBytes, bytes)
    }

    @Test
    fun testStopDataStreamRaceCommand() {
        val dataStreamRaceCommand = DataStreamRaceCommand(
            DataStreamRaceCommand.DataStreamType.STOP_STREAM)
        val bytes = dataStreamRaceCommand.getBytes()
        val expectedBytes = byteArrayOf(0x05, 0x5A, 0x05, 0x00, 0x01, 0x00, 0x05, 0x02, 0x00)
        assertArrayEquals(expectedBytes, bytes)
    }
}