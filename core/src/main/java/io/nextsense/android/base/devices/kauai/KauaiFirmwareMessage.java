package io.nextsense.android.base.devices.kauai;

import io.nextsense.android.base.KauaiFirmwareMessageProto;

public class KauaiFirmwareMessage {

  private final KauaiFirmwareMessageProto.MessageType type;
  private KauaiFirmwareMessageProto.ClientMessage.Builder builder;

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
    return builder.build().toByteArray();
  }
}
