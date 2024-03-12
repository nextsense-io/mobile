package io.nextsense.android.base.devices.kauai;

import java.nio.ByteBuffer;

/**
 * Request an AUX packet from the device.
 */
public class RequestAuxPacketCommand extends KauaiFirmwareCommand {

  private static final byte STATE_PACKET = (byte)0x01;

  public RequestAuxPacketCommand() {
    super(KauaiMessageType.REQUEST_AUX_PACKET);
  }

  @Override
  public byte[] getCommand() {
    ByteBuffer buf = ByteBuffer.allocate(3);
    buf.put(getType().getCode());
    buf.put(STATE_PACKET);
    buf.rewind();
    return buf.array();
  }
}
