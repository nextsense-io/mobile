package io.nextsense.android.base.devices.kauai;

import com.google.protobuf.InvalidProtocolBufferException;

import org.greenrobot.eventbus.EventBus;

import java.nio.ByteBuffer;

import io.nextsense.android.base.KauaiFirmwareMessageProto;
import io.nextsense.android.base.devices.FirmwareMessageParsingException;
import io.nextsense.android.base.utils.RotatingFileLogger;

public class KauaiProtoDataParser {

  private static final String TAG = KauaiProtoDataParser.class.getSimpleName();

  private KauaiProtoDataParser() {}

  public static KauaiProtoDataParser create() {
    return new KauaiProtoDataParser();
  }

  enum IncomingMessageType {
    INVALID,
    RESPONSE,
    EVENT
  }

  public void parseProtoDataBytes(byte[] values) throws FirmwareMessageParsingException {
    if (values.length < 5) {
      throw new FirmwareMessageParsingException("Empty values, cannot parse device proto data.");
    }
    ByteBuffer valuesBuffer = ByteBuffer.wrap(values);
    valuesBuffer.order(KauaiDevice.BYTE_ORDER);
    long protoLength = valuesBuffer.getInt() & 0xffffffffL;
    if (protoLength > values.length - 4) {
      throw new FirmwareMessageParsingException("Proto length of " + protoLength +
          " bigger than values: " + values.length);
    }
    try {
      byte[] protoBytes = new byte[(int) protoLength];
      valuesBuffer.get(protoBytes);
      KauaiFirmwareMessageProto.HostMessage hostMessage =
          KauaiFirmwareMessageProto.HostMessage.parseFrom(protoBytes);
      IncomingMessageType incomingMessageType = IncomingMessageType.INVALID;
      switch (hostMessage.getMessageType()) {
        case GET_DEVICE_INFO:
          if (!hostMessage.hasDeviceInfo()) {
            throw new FirmwareMessageParsingException(
                "GET_DEVICE_INFO message without device info");
          }
          incomingMessageType = IncomingMessageType.RESPONSE;
          break;
        case GET_DEVICE_STATUS:
          if (!hostMessage.hasDeviceStatus()) {
            throw new FirmwareMessageParsingException(
                "GET_DEVICE_STATUS message without device status");
          }
          incomingMessageType = IncomingMessageType.RESPONSE;
          break;
        case GET_RECORDING_SETTINGS:
          if (!hostMessage.hasRecordingSettings()) {
            throw new FirmwareMessageParsingException(
                "GET_RECORDING_SETTINGS message without recording settings");
          }
          incomingMessageType = IncomingMessageType.RESPONSE;
          break;
        case SET_RECORDING_SETTINGS:
        case SET_DATE_TIME:
          if (!hostMessage.hasResult()) {
            throw new FirmwareMessageParsingException(
                "SET message without result");
          }
          incomingMessageType = IncomingMessageType.RESPONSE;
          break;
        case NOTIFY_EVENT:
//          if (!hostMessage.hasEventType()) {
//            throw new FirmwareMessageParsingException(
//                "NOTIFY_EVENT message without event type");
//          }
          incomingMessageType = IncomingMessageType.EVENT;
          break;
        default:
          RotatingFileLogger.get().logw(TAG, "Invalid message type: " +
              hostMessage.getMessageType());
      }
      switch (incomingMessageType) {
        case RESPONSE:
          EventBus.getDefault().post(new KauaiHostResponse(hostMessage));
          break;
        case EVENT:
          EventBus.getDefault().post(new KauaiHostEvent(hostMessage));
          break;
        default:
          RotatingFileLogger.get().logw(TAG, "Invalid message type: " +
              hostMessage.getMessageType());
      }
    } catch (InvalidProtocolBufferException e) {
      throw new FirmwareMessageParsingException("Error parsing proto data: " + e.getMessage());
    }
  }
}
