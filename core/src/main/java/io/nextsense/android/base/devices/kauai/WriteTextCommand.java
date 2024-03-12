package io.nextsense.android.base.devices.kauai;

import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;

/**
 * Command for writing a text value in the device log file header.
 */
public class WriteTextCommand extends KauaiFirmwareCommand {

  private final String text;
  private final byte[] endBytes = new byte[]{0x0D, 0x00};

  public WriteTextCommand(String text) {
    super(KauaiMessageType.WRITE_TEXT);
    this.text = text;
  }

  @Override
  public byte[] getCommand() {
    ByteBuffer buf = ByteBuffer.allocate(4 + text.length());
    buf.put(getType().getCode());
    buf.put(text.getBytes(StandardCharsets.UTF_8));
    buf.put(endBytes);
    buf.rewind();
    return buf.array();
  }
}
