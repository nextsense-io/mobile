package io.nextsense.android.base.devices.xenon;

import java.nio.ByteBuffer;
import java.time.Instant;

import javax.annotation.concurrent.Immutable;

/**
 * Command to set the clock in the Xenon device.
 */
@Immutable
public final class SetTimeCommand extends XenonFirmwareCommand {

  private static final byte RTC_CALIBRATION_VALUE = 0x00;

  private final Instant time;

  public SetTimeCommand(Instant time) {
    super(XenonMessageType.SET_TIME);
    this.time = time;
  }

  @Override
  public byte[] getCommand() {
    ByteBuffer buf = ByteBuffer.allocate(7);
    buf.put(getType().getCode());
    buf.putInt((int)time.getEpochSecond());
    buf.put(RTC_CALIBRATION_VALUE);
    buf.rewind();
    return buf.array();
  }
}
