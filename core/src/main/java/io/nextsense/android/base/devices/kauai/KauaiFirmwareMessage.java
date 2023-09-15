package io.nextsense.android.base.devices.kauai;

import java.nio.ByteBuffer;

import io.nextsense.android.base.KauaiFirmwareMessageProto;

public class KauaiFirmwareMessage {

  private final KauaiFirmwareMessageProto.MessageType type;
  private final KauaiFirmwareMessageProto.ClientMessage.Builder builder;

  public KauaiFirmwareMessage(KauaiFirmwareMessageProto.MessageType type, int id) {
    this.type = type;
    this.builder = KauaiFirmwareMessageProto.ClientMessage.newBuilder();
    this.builder.setMessageType(type);
    this.builder.setMessageId(id);
  }

  public KauaiFirmwareMessageProto.MessageType getType() {
    return type;
  }

  protected KauaiFirmwareMessageProto.ClientMessage.Builder getBuilder() {
    return builder;
  }

  public byte[] getCommand() {
    byte[] commandBytes = builder.build().toByteArray();
    ByteBuffer buffer = ByteBuffer.allocate(commandBytes.length + 4);
    buffer.order(KauaiDevice.BYTE_ORDER);
    // First 4 bytes contain the length of the serialized protobuf message. Convert it to unsigned.
    buffer.putInt((short) commandBytes.length & 0xffff);
    buffer.put(commandBytes);
    return buffer.array();
  }
}
