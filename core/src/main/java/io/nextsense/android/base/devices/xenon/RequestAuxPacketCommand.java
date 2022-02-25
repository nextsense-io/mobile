package io.nextsense.android.base.devices.xenon;

import java.nio.ByteBuffer;

/**
 * Request an AUX packet from the device.
 */
public class RequestAuxPacketCommand extends XenonFirmwareCommand {

  private static final byte STATE_PACKET = 0x01;

  public RequestAuxPacketCommand() {
    super(XenonMessageType.REQUEST_AUX_PACKET);
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
