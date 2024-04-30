package io.nextsense.android.base.devices;

/**
 * Created by Eric Bouchard on 8/28/2023.
 */
public enum StreamingStartMode {
  NO_LOGGING((byte)0x00),
  WITH_LOGGING((byte)0x01),
  PREPARE_ONLY((byte)0x02),
  LOGGING_AFTER_PREPARE((byte)0x03);

  public final byte value;

  StreamingStartMode(byte value) {
    this.value = value;
  }
}
