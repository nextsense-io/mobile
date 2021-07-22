package io.nextsense.android.base.devices.h1;

/**
 *
 */
public class H1FirmwareCommand {

  private final H1MessageType type;

  public H1FirmwareCommand(H1MessageType type) {
    this.type = type;
  }

  public H1MessageType getType() {
    return type;
  }

  public byte[] getCommand() {
    return new byte[]{};
  }
}
