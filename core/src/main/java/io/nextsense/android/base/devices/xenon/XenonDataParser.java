package io.nextsense.android.base.devices.xenon;

import static java.lang.Math.pow;

import com.google.common.collect.ImmutableList;

import org.greenrobot.eventbus.EventBus;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.Optional;

import io.nextsense.android.base.data.Acceleration;
import io.nextsense.android.base.data.DeviceInternalState;
import io.nextsense.android.base.data.EegSample;
import io.nextsense.android.base.data.LocalSession;
import io.nextsense.android.base.data.LocalSessionManager;
import io.nextsense.android.base.data.Sample;
import io.nextsense.android.base.data.Samples;
import io.nextsense.android.base.devices.FirmwareMessageParsingException;
import io.nextsense.android.base.utils.RotatingFileLogger;
import io.nextsense.android.base.utils.Util;

/**
 * Parser for the binary response format of the H1 device.
 */
public class XenonDataParser {

  private static final String TAG = XenonDataParser.class.getSimpleName();
  private static final List<Byte> BIT_MASKS = ImmutableList.of(
      (byte)0x01, (byte)0x02, (byte)0x04, (byte)0x08, (byte)0x10, (byte)0x20, (byte)0x40, (byte)0x80
  );
  private static final byte ACTIVE_CHANNELS_AUX_PACKET = 0x00;
  private static final byte AUX_PACKET_STATUS_TYPE = 0x01;
  private static final byte AUX_STATUS_PACKET_VERSION = 0x00;
  private static final int DATA_TIMESTAMP_SIZE_BYTES = 6;
  private static final int DATA_ACCELERATION_SIZE_BYTES = 6;
  private static final int DATA_CHANNEL_SIZE_BYTES = 3;
  private static final int DATA_FLAGS_SIZE_BYTES = 1;
  private static final float V_REF = 4.5f;

  private static final int BUSY_FLAG_INDEX = 15;
  private static final int USD_PRESENT_FLAG_INDEX = 14;
  private static final int HDMI_PRESENT_FLAG_INDEX = 13;
  private static final int RTC_SET_FLAG_INDEX = 12;
  private static final int CAPTURE_RUNNING_FLAG_INDEX = 11;
  private static final int BATTERY_CHARGING_FLAG_INDEX = 10;
  private static final int BATTERY_LOW_FLAG_INDEX = 9;
  private static final int BINARY_USD_LOGGING_ENABLED_FLAG_INDEX = 8;
  private static final int INTERNAL_ERROR_FLAG_INDEX = 0;

  private final LocalSessionManager localSessionManager;
  boolean printedDataPackerWarning = false;

  private XenonDataParser(LocalSessionManager localSessionManager) {
    this.localSessionManager = localSessionManager;
  }

  public static XenonDataParser create(LocalSessionManager localSessionManager) {
    return new XenonDataParser(localSessionManager);
  }

  public void parseDataBytes(byte[] values, int channelsCount) throws
      FirmwareMessageParsingException {
    Instant receptionTimestamp = Instant.now();
    if (values.length < 1) {
      throw new FirmwareMessageParsingException("Empty values, cannot parse device data.");
    }
    ByteBuffer valuesBuffer = ByteBuffer.wrap(values);
    byte activeChannelFlags = valuesBuffer.get();
    if (activeChannelFlags == ACTIVE_CHANNELS_AUX_PACKET) {
      parseAuxPacket(valuesBuffer);
      return;
    }
    List<Integer> activeChannels = getActiveChannelList(activeChannelFlags, channelsCount);
    int packetSize = getDataPacketSize(activeChannels.size());
    if (valuesBuffer.remaining() < packetSize) {
      throw new FirmwareMessageParsingException("Data is too small to parse one packet. Expected " +
          "minimum size of " + (packetSize + 1) + " but got " + values.length);
    }
    Samples samples = Samples.create();
    boolean canParsePacket = true;
    Instant previousTimestamp = null;
    while (canParsePacket && valuesBuffer.remaining() >= packetSize) {
      Optional<Sample> sampleOptional =
          parseDataPacket(valuesBuffer, activeChannels, receptionTimestamp);
      if (sampleOptional.isPresent()) {
        Sample sample = sampleOptional.get();
        if (previousTimestamp != null &&
            previousTimestamp.isAfter(sample.getEegSample().getAbsoluteSamplingTimestamp())) {
          RotatingFileLogger.get().logw(TAG, "Received a sample that is before a previous sample, skipping sample. " +
              "Previous timestamp: " + previousTimestamp + ", current timestamp: " +
              sample.getEegSample().getAbsoluteSamplingTimestamp());
          break;
        }
        samples.addEegSample(sample.getEegSample());
        samples.addAcceleration(sample.getAcceleration());
        previousTimestamp = sample.getEegSample().getAbsoluteSamplingTimestamp();
      }
      canParsePacket = sampleOptional.isPresent();
    }
    EventBus.getDefault().post(samples);
    Instant parseEndTime = Instant.now();
    long parseTime = parseEndTime.toEpochMilli() - receptionTimestamp.toEpochMilli();
    if (parseTime > 30) {
      RotatingFileLogger.get().logd(TAG, "It took " + parseTime + " to parse xenon data.");
    }
  }

  private static float convertToMicroVolts(int data) {
    // TODO(eric): Get current channel EEG gain from device state.
    return (float)(data * ((V_REF * 1000000.0f) / (24.0f * (pow(2, 23) - 1))));
  }

  private Optional<Sample> parseDataPacket(ByteBuffer valuesBuffer, List<Integer> activeChannels,
                               Instant receptionTimestamp) throws NoSuchElementException {
    Optional<LocalSession> localSessionOptional = localSessionManager.getActiveLocalSession();
    if (!localSessionOptional.isPresent()) {
      if (!printedDataPackerWarning) {
        RotatingFileLogger.get().logw(TAG, "Received data packet without an active session, cannot record it.");
        printedDataPackerWarning = true;
      }
      return Optional.empty();
    }
    LocalSession localSession = localSessionOptional.get();
    valuesBuffer.order(ByteOrder.LITTLE_ENDIAN);
    List<Short> accelerationData = Arrays.asList(valuesBuffer.getShort(), valuesBuffer.getShort(),
        valuesBuffer.getShort());
    HashMap<Integer, Float> eegData = new HashMap<>();
    for (Integer activeChannel : activeChannels) {
      // The sample is encoded in 3 bytes.
      int eegValue = Util.bytesToInt24(
          new byte[]{valuesBuffer.get(), valuesBuffer.get(), valuesBuffer.get()}, 0,
          ByteOrder.LITTLE_ENDIAN);
      eegData.put(activeChannel, convertToMicroVolts(eegValue));
    }
    long samplingTimestamp = Util.bytesToLong48(new byte[]{valuesBuffer.get(),
        valuesBuffer.get(), valuesBuffer.get(), valuesBuffer.get(), valuesBuffer.get(),
        valuesBuffer.get()}, 0, ByteOrder.LITTLE_ENDIAN);
    Instant samplingTime = Instant.ofEpochMilli(samplingTimestamp);
    Acceleration acceleration = Acceleration.create(localSession.id, /*x=*/accelerationData.get(0),
        /*y=*/accelerationData.get(1), /*z=*/accelerationData.get(2), receptionTimestamp,
        null, samplingTime);
    EegSample eegSample = EegSample.create(localSession.id, eegData, receptionTimestamp,
        null, samplingTime, SampleFlags.create(valuesBuffer.get()));
    return Optional.of(Sample.create(eegSample, acceleration));
  }

  private static int getDataPacketSize(int activeChannelsSize) {
    return DATA_ACCELERATION_SIZE_BYTES + activeChannelsSize * DATA_CHANNEL_SIZE_BYTES +
        DATA_TIMESTAMP_SIZE_BYTES + DATA_FLAGS_SIZE_BYTES;
  }

  private static List<Integer> getActiveChannelList(byte activeChannelFlags, int channelCount) {
    List<Integer> activeChannels = new ArrayList<>();
    for (int i = 0; i < channelCount; ++i) {
      byte channelMask = BIT_MASKS.get(i);
      if ((channelMask & activeChannelFlags) == channelMask) {
        activeChannels.add(i + 1);
      }
    }
    return activeChannels;
  }

  private void parseAuxPacket(ByteBuffer valuesBuffer) {
    byte auxPacketType = valuesBuffer.get();
    switch (auxPacketType) {
      case AUX_PACKET_STATUS_TYPE:
        parseAuxStatePacket(valuesBuffer);
        break;
      default:
        throw new UnsupportedOperationException(
            "Aux packet type " + auxPacketType + " is not supported.");
    }
  }

  private void parseAuxStatePacket(ByteBuffer valuesBuffer) {
    Optional<LocalSession> localSessionOptional = localSessionManager.getActiveLocalSession();
    Long localSessionId = null;
    if (localSessionOptional.isPresent()) {
      localSessionId = localSessionOptional.get().id;
    }
    valuesBuffer.order(ByteOrder.BIG_ENDIAN);
    byte versionNumber = valuesBuffer.get();
    if (versionNumber != AUX_STATUS_PACKET_VERSION) {
      throw new UnsupportedOperationException(
          "Aux status packet version " + versionNumber + " is not supported.");
    }
    short batteryMilliVolts = valuesBuffer.getShort();
    RotatingFileLogger.get().logd(TAG, "Battery milli volts: " + batteryMilliVolts);
    long timestampMs = Util.bytesToLong48(new byte[]{valuesBuffer.get(),
        valuesBuffer.get(), valuesBuffer.get(), valuesBuffer.get(), valuesBuffer.get(),
        valuesBuffer.get()}, 0, ByteOrder.LITTLE_ENDIAN);
    Instant timestamp = Instant.ofEpochMilli(timestampMs);
    byte leadsOffNegative = valuesBuffer.get();
    byte leadsOffPositiveValues = valuesBuffer.get();
    ArrayList<Boolean> leadsOffPositive = new ArrayList<>(8);
    for (int i = 0; i < 8; ++i) {
      byte flagMask = BIT_MASKS.get(i);
      leadsOffPositive.add((flagMask & leadsOffPositiveValues) == flagMask);
    }
    int sampleCounter = valuesBuffer.getInt();
    short statusFlags = valuesBuffer.getShort();
    // Go through all the bits and set the values in a Map by bit index.
    Map<Integer, Boolean> flagsMap = new HashMap<>();
    // The state flags are spread 2 bytes.
    for (int i = 0; i < 16; ++i) {
      byte flagMask = BIT_MASKS.get(i % 8);
      byte flags = i >= 8 ? (byte)((statusFlags >> 8) & 0xFF) : (byte)(statusFlags & 0xFF);
      flagsMap.put(i, (flagMask & flags) == flagMask);
    }
    byte masterState = valuesBuffer.get();
    byte bleFifoCounter = valuesBuffer.get();
    int lostSamplesCounter = valuesBuffer.getInt();
    byte bleRssi = valuesBuffer.get();

    DeviceInternalState deviceInternalState = DeviceInternalState.create(localSessionId, timestamp,
        batteryMilliVolts, flagsMap.get(BUSY_FLAG_INDEX), flagsMap.get(USD_PRESENT_FLAG_INDEX),
        flagsMap.get(HDMI_PRESENT_FLAG_INDEX), flagsMap.get(RTC_SET_FLAG_INDEX),
        flagsMap.get(CAPTURE_RUNNING_FLAG_INDEX), flagsMap.get(BATTERY_CHARGING_FLAG_INDEX),
        flagsMap.get(BATTERY_LOW_FLAG_INDEX), flagsMap.get(BINARY_USD_LOGGING_ENABLED_FLAG_INDEX),
        flagsMap.get(INTERNAL_ERROR_FLAG_INDEX), sampleCounter, bleFifoCounter, lostSamplesCounter,
        bleRssi, leadsOffPositive);
    EventBus.getDefault().post(deviceInternalState);
  }
}
