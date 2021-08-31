package io.nextsense.android.base.devices.h1;

/**
 *
 */
public class H1FirmwareCommand {

  public static final int COMMAND_SIZE = 1;

  private final H1MessageType type;

  public H1FirmwareCommand(H1MessageType type) {
    this.type = type;
  }

  public H1MessageType getType() {
    return type;
  }

  public byte[] getCommand() {
    return new byte[]{getType().getCode()};
  }
}
