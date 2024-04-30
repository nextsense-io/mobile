package io.nextsense.android.base.devices.kauai_medical;

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
public class KauaiMedicalDataParser {

  private static final String TAG = KauaiMedicalDataParser.class.getSimpleName();
  private static final int DATA_TIMESTAMP_SIZE_BYTES = 4;
  private static final int DATA_ACCELERATION_SIZE_BYTES = 6;
  private static final int DATA_CHANNEL_SIZE_BYTES = 3;
  private static final int DATA_FLAGS_SIZE_BYTES = 2;
  private static final int DATA_PADDING_SIZE_BYTES = 2;
  private static final float V_REF = 4.5f;

  private final LocalSessionManager localSessionManager;
  boolean printedDataPackerWarning = false;

  private KauaiMedicalDataParser(LocalSessionManager localSessionManager) {
    this.localSessionManager = localSessionManager;
  }

  public static KauaiMedicalDataParser create(LocalSessionManager localSessionManager) {
    return new KauaiMedicalDataParser(localSessionManager);
  }

  private Instant sessionStartTimestamp = null;

  public void setSessionStartTimestamp(Instant sessionStartTimestamp) {
    this.sessionStartTimestamp = sessionStartTimestamp;
  }

  public synchronized void parseDataBytes(
      byte[] values, List<Integer> activeChannels, Instant startTimestamp, int samplingRate)
      throws FirmwareMessageParsingException {
    Instant effectiveStartTimestamp;
    if (startTimestamp == null) {
      if (sessionStartTimestamp == null) {
        sessionStartTimestamp = Instant.now();
      }
      effectiveStartTimestamp = sessionStartTimestamp;
    } else {
      effectiveStartTimestamp = startTimestamp;
    }
    Instant receptionTimestamp = Instant.now();
    if (values.length < 1) {
      throw new FirmwareMessageParsingException("Empty values, cannot parse device data.");
    }
    ByteBuffer valuesBuffer = ByteBuffer.wrap(values);
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
          parseDataPacket(valuesBuffer, activeChannels, effectiveStartTimestamp, samplingRate);
      if (sampleOptional.isPresent()) {
        Sample sample = sampleOptional.get();
        if (previousTimestamp != null &&
            previousTimestamp.isAfter(sample.getEegSample().getAbsoluteSamplingTimestamp())) {
          RotatingFileLogger.get().logw(TAG,
              "Received a sample that is before a previous sample, skipping sample. " +
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
      RotatingFileLogger.get().logd(TAG, "It took " + parseTime + " to parse Kauai data.");
    }
  }

  private static float convertToMicroVolts(int data) {
    // TODO(eric): Get current channel EEG gain from device state.
    return (float)(data * ((V_REF * 1000000.0f) / (24.0f * (pow(2, 23) - 1))));
  }

  private Optional<Sample> parseDataPacket(
      ByteBuffer valuesBuffer, List<Integer> activeChannels, Instant startTimestamp,
      int samplingRate) throws NoSuchElementException {
    Optional<LocalSession> localSessionOptional = localSessionManager.getActiveLocalSession();
    if (!localSessionOptional.isPresent()) {
      if (!printedDataPackerWarning) {
        RotatingFileLogger.get().logw(TAG,
            "Received data packet without an active session, cannot record it.");
        printedDataPackerWarning = true;
      }
      return Optional.empty();
    }
    LocalSession localSession = localSessionOptional.get();
    valuesBuffer.order(KauaiMedicalDevice.BYTE_ORDER);
    HashMap<Integer, Float> eegData = new HashMap<>();
    long sampleCounter = valuesBuffer.getInt() & 0xffffffffL;
    Instant acquisitionTimestamp = startTimestamp.plusMillis(sampleCounter * (1000 / samplingRate));
    for (Integer activeChannel : activeChannels) {
      // The sample is encoded in 3 bytes.
      int eegValue = Util.bytesToInt24(
          new byte[]{valuesBuffer.get(), valuesBuffer.get(), valuesBuffer.get()}, 0,
          ByteOrder.LITTLE_ENDIAN);
      eegData.put(activeChannel, convertToMicroVolts(eegValue));
    }
    List<Short> accelerationData = Arrays.asList(valuesBuffer.getShort(), valuesBuffer.getShort(),
        valuesBuffer.getShort());
    Acceleration acceleration = Acceleration.create(localSession.id, /*x=*/accelerationData.get(0),
        /*y=*/accelerationData.get(1), /*z=*/accelerationData.get(2), acquisitionTimestamp,
        null, acquisitionTimestamp);
    EegSample eegSample = EegSample.create(localSession.id, eegData, acquisitionTimestamp,
        null, acquisitionTimestamp, /*flags=*/KauaiMedicalSampleFlags.create(valuesBuffer.get()));
    valuesBuffer.get();  // Skip the leads off flags byte.
    valuesBuffer.getShort();  // Skip the padding bytes.
    return Optional.of(Sample.create(eegSample, acceleration));
  }

  private static int getDataPacketSize(int activeChannelsSize) {
    return activeChannelsSize * DATA_CHANNEL_SIZE_BYTES + DATA_ACCELERATION_SIZE_BYTES +
        DATA_TIMESTAMP_SIZE_BYTES + DATA_FLAGS_SIZE_BYTES + DATA_PADDING_SIZE_BYTES;
  }
}
