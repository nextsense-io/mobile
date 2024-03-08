package io.nextsense.android.base.devices.kauai;

import java.util.Arrays;

/**
 * Message types that can be sent to Xenon.
 */
public enum KauaiMessageType {
  SET_TIME(new byte[]{0x00, 0x06}),
  START_STREAMING(new byte[]{0x00, 0x0A}),
  STOP_STREAMING(new byte[]{0x00, 0x0B}),
  REQUEST_AUX_PACKET(new byte[]{0x00, 0x41}),
  WRITE_TEXT(new byte[]{0x00, 0x48}),
  SET_CONFIG(new byte[]{0x00, 0x49});

  private final byte[] code;

  KauaiMessageType(byte[] code) {
    this.code = code;
  }

  public byte[] getCode() {
    return code;
  }

  public static KauaiMessageType getByCode(byte[] code) {
    return Arrays.stream(values()).filter(type -> type.getCode() == code).findFirst()
        .orElse(null);
  }
}
