package io.nextsense.android.base.devices.h1;

import javax.annotation.concurrent.Immutable;

import io.nextsense.android.base.devices.FirmwareMessageParsingException;

/**
 * H1 Firmware version response.
 */
@Immutable
public final class FirmwareVersionResponse extends H1FirmwareResponse {

  private static final int EXPECTED_MESSAGE_LENGTH = 4;
  private static final int MAJOR_NUMBER_INDEX = 1;
  private static final int MINOR_NUMBER_INDEX = 2;
  private static final int PATCH_NUMBER_INDEX = 3;

  private final int major;
  private final int minor;
  private final int patch;

  public static FirmwareVersionResponse parseFromBytes(byte[] values)
      throws FirmwareMessageParsingException {
    if (values.length == EXPECTED_MESSAGE_LENGTH) {
      int majorNumber = values[MAJOR_NUMBER_INDEX];
      int minorNumber = values[MINOR_NUMBER_INDEX];
      int patchNumber = values[PATCH_NUMBER_INDEX];
      return new FirmwareVersionResponse(majorNumber, minorNumber, patchNumber);
    } else {
      throw new FirmwareMessageParsingException(
          "Expected " + EXPECTED_MESSAGE_LENGTH + " bytes but got " + values.length + '.');
    }
  }

  private FirmwareVersionResponse(int major, int minor, int patch) {
    super(H1MessageType.FIRMWARE_VERSION);
    this.major = major;
    this.minor = minor;
    this.patch = patch;
  }

  public int getMajorVersion() {
    return major;
  }

  public int getMinorVersion() {
    return minor;
  }

  public int getPatchVersion() {
    return patch;
  }

  public String getVersion() {
    return String.valueOf(major) + '.' + minor + '.' + patch;
  }
}
