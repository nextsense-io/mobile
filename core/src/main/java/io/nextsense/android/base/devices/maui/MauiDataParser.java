package io.nextsense.android.base.devices.maui;

import static java.lang.Math.pow;

import org.greenrobot.eventbus.EventBus;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.time.Instant;
import java.util.HashMap;
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

public class MauiDataParser {
  private static final String TAG = MauiDataParser.class.getSimpleName();

  private static final float V_REF = 2.048f;
  private static final int ADC_GAIN = 128;
  private static final int AFE_EXT_AMP = 1;
  private static final int CHANNEL_1 = 1;
  private static final int HEADER_SIZE_BYTES = 1;
  private static final int EEG_SAMPLE_SIZE_BYTES = 3;
  // There are 3 components, X, Y and Z.
  private static final int MISC_ACC_COMPONENT_SIZE_BYTES = 2;

  private final LocalSessionManager localSessionManager;

  private Instant firstEegSampleTimestamp = null;
  private int eegSampleCounter = 0;

  private MauiDataParser(LocalSessionManager localSessionManager) {
    this.localSessionManager = localSessionManager;
  }

  public static MauiDataParser create(LocalSessionManager localSessionManager) {
    return new MauiDataParser(localSessionManager);
  }

  private static float convertToMicroVolts(int data) {
    return (float)(data * ((V_REF * 1000000.0f) / (ADC_GAIN * AFE_EXT_AMP * (pow(2, 23) - 1))));
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
    parseEegPacket(valuesBuffer);
  }

  private void parseEegPacket(ByteBuffer valuesBuffer) {
    Instant receptionTimestamp = Instant.now();
    if (firstEegSampleTimestamp == null) {
      firstEegSampleTimestamp = receptionTimestamp;
    }
    short sequenceNumber = (short) (valuesBuffer.get() & 0xFF);  // Unsigned int.
    RotatingFileLogger.get().logd(TAG, "Data sequence number: " + sequenceNumber);
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
    eegData.put(CHANNEL_1, convertToMicroVolts(eegValue));
    // The sampling timestamp is calculated based on the first sample timestamp and the sample rate.
    // It is not provided by the simple Maui/Softy protocol. If there are lost packets, they won't
    // be seen as the timestamp will be contiguous.
    Instant samplingTimestamp = firstEegSampleTimestamp.plusMillis(
        (long)(eegSampleCounter * 1000.0f / localSession.getEegSampleRate()));
    EegSample eegSample = EegSample.create(localSession.id, eegData, receptionTimestamp,
        null, samplingTimestamp, null);
    ++eegSampleCounter;
    return Optional.of(Sample.create(eegSample, null));
  }
}
