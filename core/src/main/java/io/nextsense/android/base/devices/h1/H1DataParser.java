package io.nextsense.android.base.devices.h1;

import android.util.Log;

import io.nextsense.android.base.Util;
import io.nextsense.android.base.devices.FirmwareMessageParsingException;

/**
 * Parser for the binary response format of the H1 device.
 */
public class H1DataParser {

  private static final String TAG = H1DataParser.class.getSimpleName();
  private static final int TYPE_INDEX = 0;

  private H1DataParser() {}

  public static H1FirmwareResponse parseDataTransRxBytes(byte[] values)
      throws FirmwareMessageParsingException {
    switch (H1MessageType.getByCode(values[TYPE_INDEX])) {
      case FIRMWARE_VERSION:
        Util.logd(TAG, "firmware version $values");
        return FirmwareVersionResponse.parseFromBytes(values);
      case BATTERY_INFO:
        Util.logd(TAG, "battery information $values");
        return BatteryInfoResponse.parseFromBytes(values);
      case BATTERY_STATUS:
        Util.logd(TAG, "battery charging status $values");
        if (values.length == 2) {
          int chargingStatus = values[1];
          switch (chargingStatus) {
            case 1:
              Util.logd(TAG, "charging status : Charging");
              break;
            case 2:
              Util.logd(TAG, "charging status : Charging Done");
              break;
            case 3:
              Util.logd(TAG, "charging status : Not Charging (Draining)");
              break;
            case 4:
              Util.logd(TAG, "charging status : Battery Low");
              break;
            default:
              Log.w(TAG, "Unknown battery status: " + chargingStatus + '.');
          }
        } else {
          throw new FirmwareMessageParsingException(
              "Expected 2 bytes but got " + values.length + '.');
        }
        // TODO(eric): Create custom message.
        return new H1FirmwareResponse(H1MessageType.BATTERY_STATUS);
      case TIME_SYNCED:
        Util.logd(TAG, "time synced value $values");
        if (values.length == 2) {
          if (values[1] == 1) {
            Util.logd(TAG, "time synced");
          } else {
            Util.logd(TAG, "time not synced");
          }
        } else {
          throw new FirmwareMessageParsingException(
              "Expected 2 bytes but got " + values.length + '.');
        }
        // TODO(eric): Create custom message.
        return new H1FirmwareResponse(H1MessageType.TIME_SYNCED);
      case SET_TIME:
        Util.logd(TAG, "time set");
        return SetTimeResponse.parseFromBytes(values);
      case GET_TIME:
        Util.logd(TAG, "get time value $values");
        if (values.length == 7) {
          Util.logd(TAG, "got time sync value");
        } else {
          throw new FirmwareMessageParsingException(
              "Expected 7 bytes for GET_TIME response, but got " + values.length + ".");
        }
        // TODO(eric): Create custom message.
        return new H1FirmwareResponse(H1MessageType.GET_TIME);
      default:
        throw new FirmwareMessageParsingException("Unknown response code " + values[TYPE_INDEX]);
    }
  }
}
