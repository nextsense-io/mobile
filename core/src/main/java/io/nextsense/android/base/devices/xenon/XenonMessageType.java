package io.nextsense.android.base.devices.xenon;

import java.util.Arrays;

/**
 * Message types that can be sent to Xenon.
 */
public enum XenonMessageType {
  SET_TIME(new byte[]{0x00, 0x06}),
  START_STREAMING(new byte[]{0x00, 0x0A}),
  STOP_STREAMING(new byte[]{0x00, 0x0B});

  private final byte[] code;

  XenonMessageType(byte[] code) {
    this.code = code;
  }

  public byte[] getCode() {
    return code;
  }

  public static XenonMessageType getByCode(byte[] code) {
    return Arrays.stream(values()).filter(type -> type.getCode() == code).findFirst()
        .orElse(null);
  }
}
