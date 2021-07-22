package io.nextsense.android.base.devices.h1;

import javax.annotation.concurrent.Immutable;

import io.nextsense.android.base.devices.FirmwareMessageParsingException;

/**
 * H1 SetTime command response. Indicates if the time was parsed and set with success on the device.
 */
@Immutable
public final class SetTimeResponse extends H1FirmwareResponse {

  private static final int EXPECTED_MESSAGE_LENGTH = 2;
  private static final int TIME_SET_RESULT_INDEX = 1;
  private static final int TIME_SET_SUCCESS = 1;
  private static final int TIME_SET_FAILURE = 2;

  private final boolean timeSet;

  public static SetTimeResponse parseFromBytes(byte[] values)
      throws FirmwareMessageParsingException {
    boolean timeSet = false;
    if (values.length == EXPECTED_MESSAGE_LENGTH) {
      switch(values[TIME_SET_RESULT_INDEX]) {
        case TIME_SET_SUCCESS:
          timeSet = true;
          break;
        case TIME_SET_FAILURE:
          break;
        default:
          throw new FirmwareMessageParsingException("Unexpected value: " + values[1] + '.');
      }
    } else {
      throw new FirmwareMessageParsingException(
          "Expected 2 bytes for SET_TIME response, but got " + values.length + ".");
    }
    return new SetTimeResponse(timeSet);
  }

  private SetTimeResponse(boolean timeSet) {
    super(H1MessageType.SET_TIME);
    this.timeSet = timeSet;
  }

  public boolean getTimeSet() {
    return timeSet;
  }
}
