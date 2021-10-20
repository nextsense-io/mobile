package io.nextsense.android.base.devices.xenon;

import java.nio.ByteBuffer;

import javax.annotation.concurrent.Immutable;

/**
 * Starts streaming of Data from the Xenon Device. It also starts recording in the device's SDCARD
 * LOG file depending on the parameter.
 */
@Immutable
public final class StartStreamingCommand extends XenonFirmwareCommand {

  public enum StartMode {
    NO_LOGGING((byte)0x00),
    WITH_LOGGING((byte)0x01),
    PREPARE_ONLY((byte)0x02),
    LOGGING_AFTER_PREPARE((byte)0x03);

    final byte value;

    StartMode(byte value) {
      this.value = value;
    }
  }

  final StartMode startMode;

  public StartStreamingCommand(StartMode startMode) {
    super(XenonMessageType.START_STREAMING);
    this.startMode = startMode;
  }

  @Override
  public byte[] getCommand() {
    ByteBuffer buf = ByteBuffer.allocate(3);
    buf.put(getType().getCode());
    buf.put(startMode.value);
    buf.rewind();
    return buf.array();
  }
}
