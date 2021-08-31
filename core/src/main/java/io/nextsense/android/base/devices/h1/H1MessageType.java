package io.nextsense.android.base.devices.h1;

import java.util.Arrays;

/**
 * Created by Eric Bouchard on 7/20/2021.
 */
public enum H1MessageType {
  FIRMWARE_VERSION((byte)0x01),
  BATTERY_INFO((byte)0x02),
  BATTERY_STATUS((byte)0x03),
  TIME_SYNCED((byte)0x04),
  SET_TIME((byte)0x05),
  GET_TIME((byte)0x06),
  STOP_STREAMING((byte)0x80),
  START_STREAMING((byte)0x81);

  private final byte code;

  H1MessageType(byte code) {
    this.code = code;
  }

  public byte getCode() {
    return code;
  }

  public static H1MessageType getByCode(byte code) {
    return Arrays.stream(values()).filter(type -> type.getCode() == code).findFirst()
        .orElse(null);
  }
}
