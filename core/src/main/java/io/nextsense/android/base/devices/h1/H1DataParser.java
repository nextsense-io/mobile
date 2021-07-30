package io.nextsense.android.base.devices.h1;

import static java.lang.Math.pow;

import android.util.Log;

import com.google.common.collect.ImmutableList;

import org.greenrobot.eventbus.EventBus;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.nextsense.android.base.utils.Util;
import io.nextsense.android.base.data.Acceleration;
import io.nextsense.android.base.data.EegSample;
import io.nextsense.android.base.devices.FirmwareMessageParsingException;

/**
 * Parser for the binary response format of the H1 device.
 */
public class H1DataParser {

  private static final String TAG = H1DataParser.class.getSimpleName();
  private static final List<Byte> CHANNEL_MASKS = ImmutableList.of(
      (byte)0x01, (byte)0x02, (byte)0x04, (byte)0x08, (byte)0x10, (byte)0x20, (byte)0x40, (byte)0x80
  );
  private static final int DATA_TRANS_RX_TYPE_INDEX = 0;
  private static final int DATA_TIMESTAMP_SIZE_BYTES = 4;
  private static final int DATA_ACCELERATION_SIZE_BYTES = 6;
  private static final int DATA_CHANNEL_SIZE_BYTES = 3;
  private static final float V_REF = 4.5f;

  private H1DataParser() {}

  public static void parseDataBytes(byte[] values, int channelsCount) throws
      FirmwareMessageParsingException {
    Instant receptionTimestamp = Instant.now();
    if (values.length < 1) {
      throw new FirmwareMessageParsingException("Empty values, cannot parse device data.");
    }
    ByteBuffer valuesBuffer = ByteBuffer.wrap(values);
    valuesBuffer.order(ByteOrder.LITTLE_ENDIAN);
    byte activeChannelFlags = valuesBuffer.get();
    List<Integer> activeChannels = getActiveChannelList(activeChannelFlags, channelsCount);
    int packetSize = getPacketSize(activeChannels.size());
    if (valuesBuffer.remaining() < packetSize) {
      throw new FirmwareMessageParsingException("Data is too small to parse one packet. Expected " +
          "minimum size of " + (packetSize + 1) + " but got " + values.length);
    }
    while (valuesBuffer.remaining() >= packetSize) {
      parsePacket(valuesBuffer, activeChannels, receptionTimestamp);
    }
  }

  private static float convertToMicroVolts(int data) {
    // TODO(eric): Get current channel EEG gain from device state.
    return (float)(data * ((V_REF * 1000000) / (24 * (pow(2, 23) - 1))));
  }

  private static void parsePacket(ByteBuffer valuesBuffer, List<Integer> activeChannels,
                                  Instant receptionTimestamp) {
    int samplingTimestamp = valuesBuffer.getInt();
    Acceleration acceleration = Acceleration.create(/*x=*/valuesBuffer.getShort(),
        /*y=*/valuesBuffer.getShort(), /*z=*/valuesBuffer.getShort(), receptionTimestamp,
        samplingTimestamp,null);
    EventBus.getDefault().post(acceleration);
    Map<Integer, Float> eegData = new HashMap<>();
    for (Integer activeChannel : activeChannels) {
      // The sample is encoded in 3 bytes.
      int eegValue = Util.bytesToInt24(
          new byte[]{valuesBuffer.get(), valuesBuffer.get(), valuesBuffer.get()}, 0,
          ByteOrder.LITTLE_ENDIAN);
      eegData.put(activeChannel, convertToMicroVolts(eegValue));
    }
    EegSample eegSample = EegSample.create(eegData, receptionTimestamp, samplingTimestamp, null);
    EventBus.getDefault().post(eegSample);
  }

  private static int getPacketSize(int activeChannelsSize) {
    return DATA_TIMESTAMP_SIZE_BYTES + DATA_ACCELERATION_SIZE_BYTES + activeChannelsSize *
        DATA_CHANNEL_SIZE_BYTES;
  }

  public static H1FirmwareResponse parseDataTransRxBytes(byte[] values) throws
      FirmwareMessageParsingException {
    switch (H1MessageType.getByCode(values[DATA_TRANS_RX_TYPE_INDEX])) {
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
        throw new FirmwareMessageParsingException(
            "Unknown response code " + values[DATA_TRANS_RX_TYPE_INDEX]);
    }
  }

  private static List<Integer> getActiveChannelList(byte activeChannelFlags, int channelCount) {
    List<Integer> activeChannels = new ArrayList<>();
    for (int i = 0; i < channelCount; ++i) {
      byte channelMask = CHANNEL_MASKS.get(i);
      if ((channelMask & activeChannelFlags) == channelMask) {
        activeChannels.add(i);
      }
    }
    return activeChannels;
  }
}
