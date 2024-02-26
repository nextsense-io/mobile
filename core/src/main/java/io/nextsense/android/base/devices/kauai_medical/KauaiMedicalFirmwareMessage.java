package io.nextsense.android.base.devices.kauai_medical;

import java.nio.ByteBuffer;

import io.nextsense.android.base.KauaiFirmwareMessageProto;

public class KauaiMedicalFirmwareMessage {

  private final KauaiFirmwareMessageProto.MessageType type;
  private final int messageId;
  private final KauaiFirmwareMessageProto.ClientMessage.Builder builder;

  public KauaiMedicalFirmwareMessage(KauaiFirmwareMessageProto.MessageType type, int id) {
    this.type = type;
    messageId = id;
    builder = KauaiFirmwareMessageProto.ClientMessage.newBuilder();
    builder.setMessageType(type);
    builder.setMessageId(id);
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
    buffer.order(KauaiMedicalDevice.BYTE_ORDER);
    // First 4 bytes contain the length of the serialized protobuf message. Convert it to unsigned.
    buffer.putInt((short) commandBytes.length & 0xffff);
    buffer.put(commandBytes);
    return buffer.array();
  }

  public int getMessageId() {
    return messageId;
  }
}
