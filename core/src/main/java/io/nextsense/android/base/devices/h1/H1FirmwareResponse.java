package io.nextsense.android.base.devices.h1;

/**
 *
 */
public class H1FirmwareResponse {

  private final H1MessageType type;

  public H1FirmwareResponse(H1MessageType type) {
    this.type = type;
  }

  public H1MessageType getType() {
    return type;
  }
}
