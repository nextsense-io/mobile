package io.nextsense.android.base.devices.nitro;

import static java.lang.Math.pow;

import org.greenrobot.eventbus.EventBus;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.time.Instant;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.Optional;

import io.nextsense.android.base.data.Acceleration;
import io.nextsense.android.base.data.DeviceLocation;
import io.nextsense.android.base.data.EegSample;
import io.nextsense.android.base.data.LocalSession;
import io.nextsense.android.base.data.LocalSessionManager;
import io.nextsense.android.base.data.Sample;
import io.nextsense.android.base.data.Samples;
import io.nextsense.android.base.devices.FirmwareMessageParsingException;
import io.nextsense.android.base.utils.Util;

public class NitroDataParser {

  private static final float V_REF = 2.048f;
  private static final int ADC_GAIN = 128;
  private static final int AFE_EXT_AMP = 1;
  private static final int CHANNEL_1 = 1;
  private static final int PACKET_TYPE_EEG = 1;
  private static final int PACKET_TYPE_MISC = 2;
  private static final int HEADER_SIZE_BYTES = 1;
  private static final int EEG_SAMPLE_SIZE_BYTES = 3;
  private static final int MISC_PACKET_COUNTER_OFFSET = 2;
  private static final int MISC_PACKET_COUNTER_SIZE = 2;
  private static final int MISC_ACC_OFFSET = 4;
  // There are 3 components, X, Y and Z.
  private static final int MISC_ACC_COMPONENT_SIZE_BYTES = 2;
  private static final int MID_VALUE_24_BITS = 8388608;

  private final LocalSessionManager localSessionManager;

  private Instant firstEegSampleTimestamp = null;
  private int eegSampleCounter = 0;

  private NitroDataParser(LocalSessionManager localSessionManager) {
    this.localSessionManager = localSessionManager;
  }

  public static NitroDataParser create(LocalSessionManager localSessionManager) {
    return new NitroDataParser(localSessionManager);
  }

  private static float convertToMicroVolts(int data) {
    return (float)(data * ((V_REF * 1000000.0f) / (ADC_GAIN * AFE_EXT_AMP * (pow(2, 23) - 1))));
  }

  // The values that come from the device have half of the 24 bits int max value added so that they
  // can't be negative. Need to subtract it to get the real value.
  private int makeSigned(int data) {
    return data - MID_VALUE_24_BITS;
  }

  public void startNewSession() {
    firstEegSampleTimestamp = null;
    eegSampleCounter = 0;
  }

  public synchronized void parseDataBytes(byte[] values) throws
      FirmwareMessageParsingException {
    if (values.length < 1) {
      throw new FirmwareMessageParsingException("Empty values, cannot parse device data.");
    }
    ByteBuffer valuesBuffer = ByteBuffer.wrap(values);
    int packetType = valuesBuffer.get() >> 4 & 7;
    // Read unused header byte.
    valuesBuffer.get();
    if (packetType == PACKET_TYPE_EEG) {
      parseEegPacket(valuesBuffer);
    } else if (packetType == PACKET_TYPE_MISC) {
      parseMiscPacket(valuesBuffer);
    } else {
      throw new FirmwareMessageParsingException("Unknown packet type: " + packetType);
    }
  }

  private void parseEegPacket(ByteBuffer valuesBuffer) {
    Instant receptionTimestamp = Instant.now();
    if (firstEegSampleTimestamp == null) {
      firstEegSampleTimestamp = receptionTimestamp;
    }
    Samples samples = Samples.create();
    boolean canParsePacket = true;
    while (canParsePacket && valuesBuffer.remaining() >= EEG_SAMPLE_SIZE_BYTES) {
      Optional<Sample> sampleOptional =
          parseDataPacket(valuesBuffer, receptionTimestamp);
      if (sampleOptional.isPresent()) {
        Sample sample = sampleOptional.get();
        samples.addEegSample(sample.getEegSample());
      }
      canParsePacket = sampleOptional.isPresent();
    }
    EventBus.getDefault().post(samples);
  }

  private Optional<Sample> parseDataPacket(ByteBuffer valuesBuffer, Instant receptionTimestamp)
      throws NoSuchElementException {
    Optional<LocalSession> localSessionOptional = localSessionManager.getActiveLocalSession();
    if (!localSessionOptional.isPresent()) {
      return Optional.empty();
    }
    LocalSession localSession = localSessionOptional.get();
    valuesBuffer.order(ByteOrder.LITTLE_ENDIAN);
    int eegValue = Util.bytesToInt24(
        new byte[]{valuesBuffer.get(), valuesBuffer.get(), valuesBuffer.get()}, 0,
        ByteOrder.LITTLE_ENDIAN, /*signed=*/false);
    HashMap<Integer, Float> eegData = new HashMap<>();
    eegData.put(CHANNEL_1, convertToMicroVolts(makeSigned(eegValue)));
    // The sampling timestamp is calculated based on the first sample timestamp and the sample rate.
    // It is not provided by the simple Nitro/Softy protocol. If there are lost packets, they won't
    // be seen as the timestamp will be contiguous.
    Instant samplingTimestamp = firstEegSampleTimestamp.plusMillis(
        (long)(eegSampleCounter * 1000.0f / localSession.getEegSampleRate()));
    EegSample eegSample = EegSample.create(localSession.id, eegData, receptionTimestamp,
        null, samplingTimestamp, null);
    ++eegSampleCounter;
    return Optional.of(Sample.create(eegSample, null));
  }

  private void parseMiscPacket(ByteBuffer valuesBuffer) {
    Instant receptionTimestamp = Instant.now();
    Optional<LocalSession> localSessionOptional = localSessionManager.getActiveLocalSession();
    if (!localSessionOptional.isPresent()) {
      return;
    }
    LocalSession localSession = localSessionOptional.get();
    valuesBuffer.order(ByteOrder.BIG_ENDIAN);
    // Skip misc bytes.
    valuesBuffer.getShort();
    List<Short> accelerationData = Arrays.asList(valuesBuffer.getShort(), valuesBuffer.getShort(),
        valuesBuffer.getShort());
    Acceleration acceleration = Acceleration.create(localSession.id, /*x=*/accelerationData.get(0),
        /*y=*/accelerationData.get(1), /*z=*/accelerationData.get(2), DeviceLocation.BOX,
        receptionTimestamp, null, /*samplingTime=*/receptionTimestamp);
    Samples samples = Samples.create();
    samples.addAcceleration((Sample.create(null, acceleration).getAcceleration()));
    EventBus.getDefault().post(samples);
  }
}
