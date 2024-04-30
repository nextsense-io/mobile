package io.nextsense.android.base.devices.xenon;

import java.nio.ByteBuffer;

import javax.annotation.concurrent.Immutable;

import io.nextsense.android.base.devices.StreamingStartMode;

/**
 * Starts streaming of Data from the Xenon Device. It also starts recording in the device's SDCARD
 * LOG file depending on the parameter.
 */
@Immutable
public final class StartStreamingCommand extends XenonFirmwareCommand {

  final StreamingStartMode startMode;

  public StartStreamingCommand(StreamingStartMode startMode) {
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
