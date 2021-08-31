package io.nextsense.android.base.devices.h1;

import java.nio.ByteBuffer;
import java.time.Instant;

import javax.annotation.concurrent.Immutable;

import io.nextsense.android.base.devices.xenon.XenonFirmwareCommand;
import io.nextsense.android.base.utils.Util;

/**
 * Command to set the clock in the H1 device.
 */
@Immutable
public final class SetTimeCommand extends H1FirmwareCommand {

  private static final int LENGTH = XenonFirmwareCommand.COMMAND_SIZE + 11;
  private final Instant time;

  public SetTimeCommand(Instant time) {
    super(H1MessageType.SET_TIME);
    this.time = time;
  }

  @Override
  public byte[] getCommand() {
    long seconds = time.getEpochSecond();
    ByteBuffer buf = ByteBuffer.allocate(LENGTH);
    buf.put(getType().getCode());
    String secondsHex = Util.padString(Long.toHexString(seconds), /*length=*/8);
    for (char character : secondsHex.toCharArray()) {
      buf.put((byte)character);
    }
    String timeZone = "0000";
    for (char character : timeZone.toCharArray()) {
      buf.put((byte)character);
    }
    buf.rewind();
    return buf.array();
  }
}
