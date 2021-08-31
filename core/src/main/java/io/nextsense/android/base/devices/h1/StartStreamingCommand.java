package io.nextsense.android.base.devices.h1;

import java.nio.ByteBuffer;

import javax.annotation.concurrent.Immutable;

import io.nextsense.android.base.devices.xenon.XenonFirmwareCommand;

/**
 * Starts streaming of Data from the H1 Device. It also starts recording in the device's SDCARD LOG
 * file.
 */
@Immutable
public final class StartStreamingCommand extends H1FirmwareCommand {

  private static final int LENGTH = XenonFirmwareCommand.COMMAND_SIZE + 1;
  private static final byte WRITE_TO_SDCARD = 0x01;
  private static final byte DO_NOT_WRITE_TO_SDCARD = 0x00;

  private final boolean writeToSdcard;

  public StartStreamingCommand(boolean writeToSdcard) {
    super(H1MessageType.START_STREAMING);
    this.writeToSdcard = writeToSdcard;
  }

  @Override
  public byte[] getCommand() {
    ByteBuffer buf = ByteBuffer.allocate(LENGTH);
    buf.put(getType().getCode());
    buf.put(writeToSdcard? WRITE_TO_SDCARD: DO_NOT_WRITE_TO_SDCARD);
    buf.rewind();
    return buf.array();
  }
}
