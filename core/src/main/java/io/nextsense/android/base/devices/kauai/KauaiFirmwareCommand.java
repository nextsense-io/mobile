package io.nextsense.android.base.devices.kauai;

/**
 *
 */
public class KauaiFirmwareCommand {

  public static final int COMMAND_SIZE = 2;

  private final KauaiMessageType type;

  public KauaiFirmwareCommand(KauaiMessageType type) {
    this.type = type;
  }

  public KauaiMessageType getType() {
    return type;
  }

  public byte[] getCommand() {
    return getType().getCode();
  }
}
