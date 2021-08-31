package io.nextsense.android.base.devices.xenon;

/**
 *
 */
public class XenonFirmwareCommand {

  public static final int COMMAND_SIZE = 2;

  private final XenonMessageType type;

  public XenonFirmwareCommand(XenonMessageType type) {
    this.type = type;
  }

  public XenonMessageType getType() {
    return type;
  }

  public byte[] getCommand() {
    return getType().getCode();
  }
}
