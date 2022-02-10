package io.nextsense.android.base.devices.xenon;

import static java.lang.Math.pow;

import android.util.Log;

import com.google.common.collect.ImmutableList;

import org.greenrobot.eventbus.EventBus;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.Optional;

import io.nextsense.android.base.data.Acceleration;
import io.nextsense.android.base.data.EegSample;
import io.nextsense.android.base.data.LocalSession;
import io.nextsense.android.base.data.LocalSessionManager;
import io.nextsense.android.base.devices.FirmwareMessageParsingException;
import io.nextsense.android.base.utils.Util;

/**
 * Parser for the binary response format of the H1 device.
 */
public class XenonDataParser {

  private static final String TAG = XenonDataParser.class.getSimpleName();
  private static final List<Byte> BIT_MASKS = ImmutableList.of(
      (byte)0x01, (byte)0x02, (byte)0x04, (byte)0x08, (byte)0x10, (byte)0x20, (byte)0x40, (byte)0x80
  );
  private static final int DATA_TIMESTAMP_SIZE_BYTES = 6;
  private static final int DATA_ACCELERATION_SIZE_BYTES = 6;
  private static final int DATA_CHANNEL_SIZE_BYTES = 3;
  private static final int DATA_FLAGS_SIZE_BYTES = 1;
  private static final float V_REF = 4.5f;


  private final LocalSessionManager localSessionManager;

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
    return (float)(data * ((V_REF * 1000000.0f) / (24.0f * (pow(2, 23) - 1))));
  }

  private void parsePacket(ByteBuffer valuesBuffer, List<Integer> activeChannels,
                           Instant receptionTimestamp) throws NoSuchElementException {
    Optional<LocalSession> localSessionOptional = localSessionManager.getActiveLocalSession();
    if (!localSessionOptional.isPresent()) {
      Log.w(TAG, "Received data without an active session, cannot record it.");
      return;
    }
    LocalSession localSession = localSessionOptional.get();
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
    EventBus.getDefault().post(acceleration);
    EventBus.getDefault().post(eegSample);
  }

  private static int getPacketSize(int activeChannelsSize) {
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
}
