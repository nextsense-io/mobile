package io.nextsense.android.base.devices;

/**
 * Exception thrown when parsing the firmware message is not successful.
 */
public class FirmwareMessageParsingException extends Exception {

  public FirmwareMessageParsingException(String message) {
    super(message);
  }
}
