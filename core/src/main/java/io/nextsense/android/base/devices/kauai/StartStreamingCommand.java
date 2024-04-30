package io.nextsense.android.base.devices.kauai;

import java.nio.ByteBuffer;

import javax.annotation.concurrent.Immutable;

import io.nextsense.android.base.devices.StreamingStartMode;

/**
 * Starts streaming of Data from the Xenon Device. It also starts recording in the device's SDCARD
 * LOG file depending on the parameter.
 */
@Immutable
public final class StartStreamingCommand extends KauaiFirmwareCommand {

  final StreamingStartMode startMode;

  public StartStreamingCommand(StreamingStartMode startMode) {
    super(KauaiMessageType.START_STREAMING);
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
