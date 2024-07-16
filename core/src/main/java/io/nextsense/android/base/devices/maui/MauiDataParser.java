package io.nextsense.android.base.devices.maui;

import static java.lang.Math.pow;

import android.util.Log;

import com.google.protobuf.InvalidProtocolBufferException;

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
import io.nextsense.android.base.data.AngularSpeed;
import io.nextsense.android.base.data.DeviceLocation;
import io.nextsense.android.base.data.EegSample;
import io.nextsense.android.base.data.LocalSession;
import io.nextsense.android.base.data.LocalSessionManager;
import io.nextsense.android.base.data.Samples;
import io.nextsense.android.base.devices.FirmwareMessageParsingException;
import io.nextsense.android.base.utils.Util;
import io.nextsense.android.budz.BudzDataPacketProto;

public class MauiDataParser {
  private static final String TAG = MauiDataParser.class.getSimpleName();

  private static final float V_REF = 2.048f;
  private static final double CLOCK_TO_US_MULTIPLIER = 312.5f;
  private static final int ADC_GAIN = 128;
  private static final int AFE_EXT_AMP = 1;
  private static final int CHANNEL_LEFT = 1;
  private static final int CHANNEL_RIGHT = 2;
  // One channel at 24 bits of resolution. Real resolution is 22 bits.
  private static final int EEG_SAMPLE_SIZE_BYTES = 3;
  // Acceleration and Angular speed from the gyroscope. X, Y and Z from each at 16 bits of
  // resolution.
  private static final int IMU_SAMPLE_SIZE_BYTES = 12;

  private final LocalSessionManager localSessionManager;

  private String deviceName;
  private long lastKeyTimestampRight = 0;
  private int rightSamplesSinceKeyTimestamp = 0;
  private long lastKeyTimestampLeft = 0;
  private int leftSamplesSinceKeyTimestamp = 0;

  private MauiDataParser(LocalSessionManager localSessionManager) {
    this.localSessionManager = localSessionManager;
  }

  public static MauiDataParser create(LocalSessionManager localSessionManager) {
    return new MauiDataParser(localSessionManager);
  }

  public void setDeviceName(String deviceName) {
    this.deviceName = deviceName;
  }

  private static float convertToMicroVolts(int data) {
    return (float)(data * ((V_REF * 1000000.0f) / (ADC_GAIN * AFE_EXT_AMP * (pow(2, 23) - 1))));
  }

  public void startNewSession() {
    lastKeyTimestampRight = 0;
    rightSamplesSinceKeyTimestamp = 0;
    lastKeyTimestampLeft = 0;
    leftSamplesSinceKeyTimestamp = 0;
  }

  public synchronized void parseDataBytes(byte[] values) throws FirmwareMessageParsingException {
    if (values.length < 3) {
      throw new FirmwareMessageParsingException("Empty values, cannot parse device proto data.");
    }
    Instant receptionTimestamp = Instant.now();

    Optional<LocalSession> localSessionOptional = localSessionManager.getActiveLocalSession();
    if (!localSessionOptional.isPresent()) {
      Log.e(TAG, "No active local session found.");
      return;
    }
    LocalSession localSession = localSessionOptional.get();

    ByteBuffer valuesBuffer = ByteBuffer.wrap(values);
    valuesBuffer.order(MauiDevice.BYTE_ORDER);
    int leftProtoLength = valuesBuffer.get() & 0xff;
    int rightProtoLength = valuesBuffer.get() & 0xff;
    DeviceLocation deviceLocation;
    if (leftProtoLength == 0 && rightProtoLength == 0) {
      throw new FirmwareMessageParsingException("Both protos are empty.");
    }
    deviceLocation = leftProtoLength > 0 ? DeviceLocation.LEFT_EARBUD : DeviceLocation.RIGHT_EARBUD;
    int protoLength = deviceLocation == DeviceLocation.LEFT_EARBUD ? leftProtoLength :
        rightProtoLength;
    Log.d(TAG, "Proto length left: " + leftProtoLength + " Proto length right: " +
        rightProtoLength + ", values length: " + values.length + ". Location: " +
        deviceLocation.name() + ", device name: " + deviceName);
    // TODO(eric): Re-enable this check when the length is fixed by AUT.
    // if (protoLength > values.length - PROTO_SIZE_BYTES) {
    if (protoLength > values.length) {
      throw new FirmwareMessageParsingException("Proto length of " + protoLength +
          " bigger than values: " + values.length);
    }
    try {
      byte[] protoBytes = new byte[values.length - 2];
      valuesBuffer.get(protoBytes);
      BudzDataPacketProto.BudzDataPacket budzDataPacket =
          BudzDataPacketProto.BudzDataPacket.parseFrom(protoBytes);
      deviceLocation = budzDataPacket.getFlags() == 0 ? DeviceLocation.LEFT_EARBUD :
          DeviceLocation.RIGHT_EARBUD;

      long acquisitionTimestamp = 0;
      if (budzDataPacket.getBtClockNclk() != 0) {
        Log.w(TAG, "btClockNclk: " + budzDataPacket.getBtClockNclk() + ", btClockNclIntra: " +
            (budzDataPacket.getBtClockNclkIntra() & 0xffffL) + ", flags: " +
            budzDataPacket.getFlags());
        if (deviceLocation == DeviceLocation.RIGHT_EARBUD) {
          lastKeyTimestampRight = getTimestamp(budzDataPacket, localSession.getEegSampleRate());
          rightSamplesSinceKeyTimestamp = 0;
        } else {
          lastKeyTimestampLeft = getTimestamp(budzDataPacket, localSession.getEegSampleRate());
          leftSamplesSinceKeyTimestamp = 0;
        }
      }
      acquisitionTimestamp = deviceLocation == DeviceLocation.LEFT_EARBUD ? lastKeyTimestampLeft :
          lastKeyTimestampRight;
      if (!budzDataPacket.getEeeg().isEmpty()) {
        ByteBuffer eegBuffer = ByteBuffer.wrap(budzDataPacket.getEeeg().toByteArray());
        ByteBuffer imuBuffer = ByteBuffer.wrap(budzDataPacket.getImu().toByteArray());
        parseSampleData(eegBuffer, imuBuffer, deviceLocation, receptionTimestamp,
            acquisitionTimestamp);
      }
    } catch (InvalidProtocolBufferException e) {
      throw new FirmwareMessageParsingException("Error parsing proto data: " + e.getMessage());
    }
  }

  private long getTimestamp(BudzDataPacketProto.BudzDataPacket budzDataPacket,
                            float eegSamplingRate) {
    int eegSamplesInPacket = budzDataPacket.getEeeg().size() / EEG_SAMPLE_SIZE_BYTES;
    long uptimeMs = Math.round((budzDataPacket.getBtClockNclk() & 0xffffL) * CLOCK_TO_US_MULTIPLIER
        + (budzDataPacket.getBtClockNclkIntra() & 0xffffL)) / 1000;
    // The timestamp is the time when the last sample in this packet was collected. Subtract the
    // time to get back to the first sample of this packet.
    return uptimeMs - (long) eegSamplesInPacket * Math.round(1000 / eegSamplingRate);
  }

  private void parseSampleData(ByteBuffer eegBuffer, ByteBuffer imuBuffer,
                               DeviceLocation deviceLocation, Instant receptionTimestamp,
                               long acquisitionTimestamp) {
    Samples samples = Samples.create();
    boolean canParseEeg = true;
    while (canParseEeg && eegBuffer.remaining() >= EEG_SAMPLE_SIZE_BYTES) {
      Optional<EegSample> eegSampleOptional =
          parseSingleEegPacket(eegBuffer, receptionTimestamp, deviceLocation, acquisitionTimestamp);
      if (eegSampleOptional.isPresent()) {
        EegSample eegSample = eegSampleOptional.get();
        samples.addEegSample(eegSample);
      }
      canParseEeg = eegSampleOptional.isPresent();
    }

    while (imuBuffer.remaining() >= IMU_SAMPLE_SIZE_BYTES) {
      Acceleration acceleration = parseSingleAccelerationPacket(
          imuBuffer, receptionTimestamp, deviceLocation, acquisitionTimestamp);
      samples.addAcceleration(acceleration);
      AngularSpeed angularSpeed = parseSingleAngularSpeedPacket(
          imuBuffer, receptionTimestamp, deviceLocation, acquisitionTimestamp);
      samples.addAngularSpeed(angularSpeed);
    }

    Log.d(TAG, "Parsed " + samples.getEegSamples().size() + " EEG samples, " +
        samples.getAccelerations().size() + " accelerations and " +
        samples.getAngularSpeeds().size() + " angular speeds.");
    EventBus.getDefault().post(samples);
  }

  private Optional<EegSample> parseSingleEegPacket(
      ByteBuffer valuesBuffer, Instant receptionTimestamp, DeviceLocation deviceLocation,
      long acquisitionTimestamp) throws NoSuchElementException {
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
    eegData.put(deviceLocation == DeviceLocation.LEFT_EARBUD? CHANNEL_LEFT : CHANNEL_RIGHT,
        convertToMicroVolts(eegValue));
    int dataPointAcquisitionTimeStamp = (int) acquisitionTimestamp + (deviceLocation ==
        DeviceLocation.LEFT_EARBUD ? leftSamplesSinceKeyTimestamp : rightSamplesSinceKeyTimestamp) *
        Math.round(1000 / localSession.getEegSampleRate());
    EegSample eegSample = EegSample.create(localSession.id, eegData, receptionTimestamp,
        dataPointAcquisitionTimeStamp, /*samplingTimestamp=*/null, null);
    if (deviceLocation == DeviceLocation.LEFT_EARBUD) {
      ++leftSamplesSinceKeyTimestamp;
    } else {
      ++rightSamplesSinceKeyTimestamp;
    }
    return Optional.of(eegSample);
  }

  private Acceleration parseSingleAccelerationPacket(
      ByteBuffer valuesBuffer, Instant receptionTimestamp, DeviceLocation deviceLocation,
      long acquisitionTimestamp) throws NoSuchElementException {
    Optional<LocalSession> localSessionOptional = localSessionManager.getActiveLocalSession();
    if (!localSessionOptional.isPresent()) {
      return null;
    }
    LocalSession localSession = localSessionOptional.get();
    valuesBuffer.order(ByteOrder.LITTLE_ENDIAN);
    List<Short> accelerationData = Arrays.asList(valuesBuffer.getShort(), valuesBuffer.getShort(),
        valuesBuffer.getShort());
    return Acceleration.create(localSession.id, /*x=*/accelerationData.get(0),
        /*y=*/accelerationData.get(1), /*z=*/accelerationData.get(2), deviceLocation,
        /*samplingTimestamp=*/null, (int) acquisitionTimestamp, receptionTimestamp);
  }

  private AngularSpeed parseSingleAngularSpeedPacket(
      ByteBuffer valuesBuffer, Instant receptionTimestamp, DeviceLocation deviceLocation,
      long acquisitionTimestamp) throws NoSuchElementException {
    Optional<LocalSession> localSessionOptional = localSessionManager.getActiveLocalSession();
    if (!localSessionOptional.isPresent()) {
      return null;
    }
    LocalSession localSession = localSessionOptional.get();
    valuesBuffer.order(ByteOrder.LITTLE_ENDIAN);
    List<Short> angularSpeedData = Arrays.asList(valuesBuffer.getShort(), valuesBuffer.getShort(),
        valuesBuffer.getShort());
    return AngularSpeed.create(localSession.id, /*x=*/angularSpeedData.get(0),
        /*y=*/angularSpeedData.get(1), /*z=*/angularSpeedData.get(2), deviceLocation,
        /*samplingTimeStamp=*/null, (int) acquisitionTimestamp, receptionTimestamp);
  }
}
