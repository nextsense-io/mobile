package io.nextsense.android.base.devices.maui;

import static java.lang.Math.pow;

import android.util.Log;

import com.google.protobuf.InvalidProtocolBufferException;

import org.greenrobot.eventbus.EventBus;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.time.Duration;
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
import io.nextsense.android.base.data.SleepStageRecord;
import io.nextsense.android.base.devices.FirmwareMessageParsingException;
import io.nextsense.android.base.utils.RotatingFileLogger;
import io.nextsense.android.base.utils.Util;
import io.nextsense.android.budz.BudzDataPacketProto;

public class MauiDataParser {
  public static final int CHANNEL_LEFT = 1;
  public static final int CHANNEL_RIGHT = 2;

  private static final String TAG = MauiDataParser.class.getSimpleName();
  private static final Long UNSIGNED_INT_MAX_VALUE = 4294967295L;

  private static final double CLOCK_TO_US_MULTIPLIER = 312.5f;
  private static final float AFE_FS = 1.1f;
  private static final int AFE_GAIN = 12;
  // One channel at 24 bits of resolution. Real resolution is 22 bits.
  private static final int EEG_SAMPLE_SIZE_BYTES = 3;
  // Acceleration and Angular speed from the gyroscope. X, Y and Z from each at 16 bits of
  // resolution.
  private static final int IMU_SAMPLE_SIZE_BYTES = 12;
  // Firmware should send its uptime at least once per 5 seconds.
  private static final Duration FIRST_KEY_TIMESTAMP_TIMEOUT = Duration.ofSeconds(16);
  private static final boolean VERBOSE_LOGGING = false;
  private static final boolean SEMI_VERBOSE_LOGGING = true;

  private final LocalSessionManager localSessionManager;

  private DataSynchronizer eegDataSynchronizer;
  private DataSynchronizer imuDataSynchronizer;
  private String deviceName;
  private long lastKeyTimestampRight = 0;
  private int rightEegSamplesSinceKeyTimestamp = 0;
  private int rightImuSamplesSinceKeyTimestamp = 0;
  private long lastKeyTimestampLeft = 0;
  private int leftEegSamplesSinceKeyTimestamp = 0;
  private int leftImuSamplesSinceKeyTimestamp = 0;
  private Long lastPackageNum = null;
  private Instant firstReceptionTimestamp = null;
  private boolean useSequenceNumberAsRelativeTimestamp = false;
  private int eegSamplesCount = 0;

  private MauiDataParser(LocalSessionManager localSessionManager) {
    this.localSessionManager = localSessionManager;
  }

  public static MauiDataParser create(LocalSessionManager localSessionManager) {
    return new MauiDataParser(localSessionManager);
  }

  public void setDataSynchronizers(DataSynchronizer eegDataSynchronizer,
                                   DataSynchronizer imuDataSynchronizer) {
    this.eegDataSynchronizer = eegDataSynchronizer;
    this.imuDataSynchronizer = imuDataSynchronizer;
  }

  public void setDeviceName(String deviceName) {
    this.deviceName = deviceName;
  }

  public static float convertToMicroVolts(int data) {
    if (data <= 2097151) {  // Midpoint of 22 bits.
      return (float) (data / (pow(2, 21) - 1) * AFE_FS / AFE_GAIN) * 1000000;
    } else {
      return (float) ((data - pow(2, 22)) / pow(2, 21) * AFE_FS / AFE_GAIN) * 1000000;
    }
  }

  public void startNewSession() {
    lastKeyTimestampRight = 0;
    rightEegSamplesSinceKeyTimestamp = 0;
    rightImuSamplesSinceKeyTimestamp = 0;
    lastKeyTimestampLeft = 0;
    leftEegSamplesSinceKeyTimestamp = 0;
    leftImuSamplesSinceKeyTimestamp = 0;
    lastPackageNum = null;
    firstReceptionTimestamp = null;
    useSequenceNumberAsRelativeTimestamp = false;
    eegSamplesCount = 0;
    eegDataSynchronizer.clear();
    imuDataSynchronizer.clear();
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
    if (VERBOSE_LOGGING) {
      Log.v(TAG, "Proto length: " + leftProtoLength + ", values length: " +
          values.length + ", device name: " + deviceName);
    }
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

      long packageNum = Integer.toUnsignedLong(budzDataPacket.getPackageNum());
      if (SEMI_VERBOSE_LOGGING && packageNum % 100 == 0) {
        RotatingFileLogger.get().logv(TAG, "Proto length: " + leftProtoLength +
            ", values length: " + values.length + ", device name: " + deviceName);
      }
      long skipped = getSkippedPackets(packageNum);
      if (skipped != 0) {
        // TODO(eric): Replace the content of the field with number of eeg packets sent instead of
        //  number of packets to be able to increment the time correctly for skipped eeg samples.
//        int eegSamplesPerPacket = Math.round(1000 / localSession.getEegSampleRate()) / 20;
//        if (deviceLocation == DeviceLocation.LEFT_EARBUD) {
//          leftSamplesSinceKeyTimestamp += skipped * eegSamplesPerPacket;
//        } else {
//          rightSamplesSinceKeyTimestamp += skipped * eegSamplesPerPacket;
//        }
        RotatingFileLogger.get().logw(TAG, "Package number is not sequential. Last: " +
            lastPackageNum + ", current: " + packageNum + ", skipped: " + skipped);
      }
      lastPackageNum = packageNum;

      long acquisitionTimestamp;
      if (budzDataPacket.getBtClockNclk() != 0) {
        RotatingFileLogger.get().logv(TAG, "btClockNclk: " +
            Integer.toUnsignedLong(budzDataPacket.getBtClockNclk()) + ", btClockNclIntra: " +
            (Integer.toUnsignedLong(budzDataPacket.getBtClockNclkIntra())) + ", flags: " +
            budzDataPacket.getFlags());
        if (deviceLocation == DeviceLocation.RIGHT_EARBUD) {
          lastKeyTimestampRight = getTimestamp(budzDataPacket, localSession.getEegSampleRate());
          rightEegSamplesSinceKeyTimestamp = 0;
        } else {
          lastKeyTimestampLeft = getTimestamp(budzDataPacket, localSession.getEegSampleRate());
          leftEegSamplesSinceKeyTimestamp = 0;
        }
      } else if (deviceLocation == DeviceLocation.LEFT_EARBUD && lastKeyTimestampLeft == 0 ||
          deviceLocation == DeviceLocation.RIGHT_EARBUD && lastKeyTimestampRight == 0) {
        if (firstReceptionTimestamp == null) {
          firstReceptionTimestamp = receptionTimestamp;
        }
        if (!useSequenceNumberAsRelativeTimestamp) {
          if (Duration.between(firstReceptionTimestamp, receptionTimestamp).compareTo(
              FIRST_KEY_TIMESTAMP_TIMEOUT) > 0) {
            RotatingFileLogger.get().logi(TAG, "First key timestamp not received after " +
                FIRST_KEY_TIMESTAMP_TIMEOUT + ". Start accepting data.");
            useSequenceNumberAsRelativeTimestamp = true;
          } else {
            RotatingFileLogger.get().logd(TAG, "Data packet before first key timestamp, ignoring.");
            return;
          }
        }
      }
      if (!useSequenceNumberAsRelativeTimestamp) {
        acquisitionTimestamp = deviceLocation == DeviceLocation.LEFT_EARBUD ? lastKeyTimestampLeft :
            lastKeyTimestampRight;
      } else {
        // TODO(eric): Replace this counter with the package number when it is fixed by AUT.
        acquisitionTimestamp =
            (long) eegSamplesCount * Math.round(1000 / localSession.getEegSampleRate());
      }

      if (!budzDataPacket.getEeeg().isEmpty()) {
        parseSampleData(budzDataPacket, deviceLocation, receptionTimestamp,
            acquisitionTimestamp);
      }
    } catch (InvalidProtocolBufferException e) {
      throw new FirmwareMessageParsingException("Error parsing proto data: " + e.getMessage());
    }
  }

  private long getSkippedPackets(Long packageNum) {
    long skipped = 0;
    if (lastPackageNum != null) {
      // Check for rollover after integer limit.
      if (lastPackageNum > packageNum) {
        if (!lastPackageNum.equals(UNSIGNED_INT_MAX_VALUE) || packageNum != 0) {
          skipped = UNSIGNED_INT_MAX_VALUE - lastPackageNum + packageNum;
        }
      } else if (lastPackageNum + 1 != packageNum) {
        skipped = packageNum - lastPackageNum - 1;
      }
    }
    return skipped;
  }

  private long getTimestamp(BudzDataPacketProto.BudzDataPacket budzDataPacket,
                            float eegSamplingRate) {
    int eegSamplesInPacket = budzDataPacket.getEeeg().size() / EEG_SAMPLE_SIZE_BYTES;
    long uptimeMs = Math.round((Integer.toUnsignedLong(budzDataPacket.getBtClockNclk())) *
        CLOCK_TO_US_MULTIPLIER + (Integer.toUnsignedLong(budzDataPacket.getBtClockNclkIntra()))) /
        1000;
    // The timestamp is the time when the last sample in this packet was collected. Subtract the
    // time to go back to the first sample of this packet.
    return uptimeMs - (long) eegSamplesInPacket * Math.round(1000 / eegSamplingRate);
  }

  private void parseSampleData(BudzDataPacketProto.BudzDataPacket budzDataPacket,
                               DeviceLocation deviceLocation, Instant receptionTimestamp,
                               long acquisitionTimestamp) {
    Samples samples = Samples.create();

    if (budzDataPacket.getSleepStage() != BudzDataPacketProto.SleepStage.SLEEP_STAGE_UNSPECIFIED) {
      samples.addSleepStateRecord(new SleepStageRecord(
          SleepStageRecord.SleepStage.fromValue(budzDataPacket.getSleepStageValue()),
          receptionTimestamp,
          /*relativeSamplingTimestamp=*/null));
    }

    // Parse the EEG and IMU data and add them to the synchronizers.
//    while (imuBuffer.remaining() >= IMU_SAMPLE_SIZE_BYTES) {
//      parseSingleImuPacket(imuBuffer, receptionTimestamp, deviceLocation, acquisitionTimestamp);
//    }
//    ByteBuffer eegBuffer = ByteBuffer.wrap(budzDataPacket.getEeeg().toByteArray());
//    while (eegBuffer.remaining() >= EEG_SAMPLE_SIZE_BYTES) {
//      parseSingleEegPacket(eegBuffer, receptionTimestamp, deviceLocation, acquisitionTimestamp);
//    }

    ByteBuffer eegBuffer = ByteBuffer.wrap(budzDataPacket.getEeeg().toByteArray());
    while (eegBuffer.remaining() >= EEG_SAMPLE_SIZE_BYTES) {
      EegSample eegSample =
          parseSingleEegPacket(eegBuffer, receptionTimestamp, deviceLocation, acquisitionTimestamp);
      if (eegSample != null) {
        samples.addEegSample(eegSample);
      }
    }

    ByteBuffer imuBuffer = ByteBuffer.wrap(budzDataPacket.getImu().toByteArray());
    while (imuBuffer.remaining() >= IMU_SAMPLE_SIZE_BYTES) {
      parseSingleImuPacket(imuBuffer, receptionTimestamp, deviceLocation, acquisitionTimestamp,
          samples);
//      Acceleration acceleration = parseSingleAccelerationPacket(
//          imuBuffer, receptionTimestamp, deviceLocation, acquisitionTimestamp);
//      samples.addAcceleration(acceleration);
//      AngularSpeed angularSpeed = parseSingleAngularSpeedPacket(
//          imuBuffer, receptionTimestamp, deviceLocation, acquisitionTimestamp);
//      samples.addAngularSpeed(angularSpeed);
    }

//    // Get all synchronized data and remove old data.
//    List<Map<String, DataSynchronizer.DataPoint>> allEegSynchronizedData =
//        eegDataSynchronizer.getAllSynchronizedDataAndRemove();
//    List<Map<String, DataSynchronizer.DataPoint>> eegTimedOutData =
//        eegDataSynchronizer.removeOldData();
//    if (VERBOSE_LOGGING && !eegTimedOutData.isEmpty()) {
//      Log.w(TAG, "Sync failed for over " + DataSynchronizer.SYNC_TIMEOUT.toSeconds() +
//          " seconds. Removed " + eegTimedOutData.size() + " old EEG data points and emitted them.");
//    }
//    allEegSynchronizedData.addAll(eegTimedOutData);
//
//    List<Map<String, DataSynchronizer.DataPoint>> allImuSynchronizedData =
//        imuDataSynchronizer.getAllSynchronizedDataAndRemove();
//    List<Map<String, DataSynchronizer.DataPoint>> imuTimedOutData =
//        imuDataSynchronizer.removeOldData();
//    if (VERBOSE_LOGGING && !imuTimedOutData.isEmpty()) {
//      Log.w(TAG, "Sync failed for over " + DataSynchronizer.SYNC_TIMEOUT.toSeconds() +
//          " seconds. Removed " + imuTimedOutData.size() + " old IMU data points and emitted them.");
//    }
//    allImuSynchronizedData.addAll(imuTimedOutData);
//
//    if (!allEegSynchronizedData.isEmpty() || !allImuSynchronizedData.isEmpty()) {
//      if (VERBOSE_LOGGING) {
//        Log.d(TAG, allEegSynchronizedData.size() + " synchronised eeg samples and " +
//            allImuSynchronizedData.size() + " synchronized imu samples are ready.");
//      }
//      for (Map<String, DataSynchronizer.DataPoint> data : allEegSynchronizedData) {
//        HashMap<Integer, Float> eegDataMap = new HashMap<>();
//        int samplingTimeStamp = 0;
//        for (Map.Entry<String, DataSynchronizer.DataPoint> entry : data.entrySet()) {
//          eegDataMap.put(Integer.parseInt(entry.getKey()), entry.getValue().value);
//          samplingTimeStamp = (int) entry.getValue().samplingTimestamp;
//        }
//        Optional<LocalSession> localSessionOptional = localSessionManager.getActiveLocalSession();
//        if (!localSessionOptional.isPresent()) {
//          return;
//        }
//        samples.addEegSample(EegSample.create(localSessionOptional.get().id,
//            eegDataMap, receptionTimestamp, /*relativeSamplingTimestamp=*/samplingTimeStamp,
//            null));
//      }
//      for (Map<String, DataSynchronizer.DataPoint> data : allImuSynchronizedData) {
//        HashMap<String, Float> imuDataMap = new HashMap<>();
//        int samplingTimeStamp = 0;
//        for (Map.Entry<String, DataSynchronizer.DataPoint> entry : data.entrySet()) {
//          imuDataMap.put(entry.getKey(), entry.getValue().value);
//          samplingTimeStamp = (int) entry.getValue().samplingTimestamp;
//        }
//        boolean accLeftPresent = (imuDataMap.containsKey(Acceleration.Channels.ACC_L_X.getName()) &&
//            imuDataMap.containsKey(Acceleration.Channels.ACC_L_Y.getName()) &&
//            imuDataMap.containsKey(Acceleration.Channels.ACC_L_Z.getName()));
//        boolean accRightPresent = (imuDataMap.containsKey(Acceleration.Channels.ACC_R_X.getName()) &&
//            imuDataMap.containsKey(Acceleration.Channels.ACC_R_Y.getName()) &&
//            imuDataMap.containsKey(Acceleration.Channels.ACC_R_Z.getName()));
//        boolean gyroLeftPresent = (imuDataMap.containsKey(AngularSpeed.Channels.GYRO_L_X.getName()) &&
//            imuDataMap.containsKey(AngularSpeed.Channels.GYRO_L_Y.getName()) &&
//            imuDataMap.containsKey(AngularSpeed.Channels.GYRO_L_Z.getName()));
//        boolean gyroRightPresent = (imuDataMap.containsKey(AngularSpeed.Channels.GYRO_R_X.getName()) &&
//            imuDataMap.containsKey(AngularSpeed.Channels.GYRO_R_Y.getName()) &&
//            imuDataMap.containsKey(AngularSpeed.Channels.GYRO_R_Z.getName()));
//
//        samples.addAcceleration(Acceleration.create(
//            localSessionManager.getActiveLocalSession().get().id,
//            accLeftPresent ? Math.round(imuDataMap.get(Acceleration.Channels.ACC_L_X.getName())) : 0,
//            accLeftPresent ? Math.round(imuDataMap.get(Acceleration.Channels.ACC_L_Y.getName())) : 0,
//            accLeftPresent ? Math.round(imuDataMap.get(Acceleration.Channels.ACC_L_Z.getName())) : 0,
//            accRightPresent ? Math.round(imuDataMap.get(Acceleration.Channels.ACC_R_X.getName())) : 0,
//            accRightPresent ? Math.round(imuDataMap.get(Acceleration.Channels.ACC_R_Y.getName())) : 0,
//            accRightPresent ? Math.round(imuDataMap.get(Acceleration.Channels.ACC_R_Z.getName())) : 0,
//            /*samplingTimestamp=*/null, samplingTimeStamp,
//            receptionTimestamp));
//        samples.addAngularSpeed(AngularSpeed.create(
//            localSessionManager.getActiveLocalSession().get().id,
//            gyroLeftPresent ? Math.round(imuDataMap.get(AngularSpeed.Channels.GYRO_L_X.getName())) : 0,
//            gyroLeftPresent ? Math.round(imuDataMap.get(AngularSpeed.Channels.GYRO_L_Y.getName())) : 0,
//            gyroLeftPresent ? Math.round(imuDataMap.get(AngularSpeed.Channels.GYRO_L_Z.getName())) : 0,
//            gyroRightPresent ? Math.round(imuDataMap.get(AngularSpeed.Channels.GYRO_R_X.getName())) : 0,
//            gyroRightPresent ? Math.round(imuDataMap.get(AngularSpeed.Channels.GYRO_R_Y.getName())) : 0,
//            gyroRightPresent ? Math.round(imuDataMap.get(AngularSpeed.Channels.GYRO_R_Z.getName())) : 0,
//            /*samplingTimestamp=*/null, samplingTimeStamp,
//            receptionTimestamp));
//      }
//      EventBus.getDefault().post(samples);
//    }

    if (VERBOSE_LOGGING) {
      Log.v(TAG, "Parsed " + samples.getEegSamples().size() + " EEG samples, " +
          samples.getAccelerations().size() + " accelerations and " +
          samples.getAngularSpeeds().size() + " angular speeds.");
    }
    EventBus.getDefault().post(samples);
  }

  private EegSample parseSingleEegPacket(
      ByteBuffer valuesBuffer, Instant receptionTimestamp, DeviceLocation deviceLocation,
      long acquisitionTimestamp) throws NoSuchElementException {
    Optional<LocalSession> localSessionOptional = localSessionManager.getActiveLocalSession();
    if (!localSessionOptional.isPresent()) {
      return null;
    }
    LocalSession localSession = localSessionOptional.get();
    valuesBuffer.order(ByteOrder.LITTLE_ENDIAN);
    int eegValue = Util.bytesToInt22(
        new byte[]{valuesBuffer.get(), valuesBuffer.get(), valuesBuffer.get()}, 0,
        ByteOrder.LITTLE_ENDIAN);
    HashMap<Integer, Float> eegData = new HashMap<>();
    eegData.put(deviceLocation == DeviceLocation.LEFT_EARBUD? CHANNEL_LEFT : CHANNEL_RIGHT,
        convertToMicroVolts(eegValue));
    int dataPointAcquisitionTimeStamp = (int) acquisitionTimestamp + (deviceLocation ==
        DeviceLocation.LEFT_EARBUD ? leftEegSamplesSinceKeyTimestamp :
        rightEegSamplesSinceKeyTimestamp) * Math.round(1000 / localSession.getEegSampleRate());
//    String channelName = deviceLocation == DeviceLocation.LEFT_EARBUD ?
//        String.valueOf(CHANNEL_LEFT) : String.valueOf(CHANNEL_RIGHT);
//    eegDataSynchronizer.addData(channelName, dataPointAcquisitionTimeStamp, receptionTimestamp,
//        convertToMicroVolts(eegValue));
    EegSample eegSample = EegSample.create(localSession.id, eegData, receptionTimestamp,
        dataPointAcquisitionTimeStamp, /*samplingTimestamp=*/null, null);
    ++eegSamplesCount;
    if (deviceLocation == DeviceLocation.LEFT_EARBUD) {
      ++leftEegSamplesSinceKeyTimestamp;
    } else {
      ++rightEegSamplesSinceKeyTimestamp;
    }
    return eegSample;
  }

  private void parseSingleImuPacket(
      ByteBuffer valuesBuffer, Instant receptionTimestamp, DeviceLocation deviceLocation,
      long acquisitionTimestamp, Samples samples) throws NoSuchElementException {
    Optional<LocalSession> localSessionOptional = localSessionManager.getActiveLocalSession();
    if (!localSessionOptional.isPresent()) {
      return;
    }
    LocalSession localSession = localSessionOptional.get();
    valuesBuffer.order(ByteOrder.LITTLE_ENDIAN);
    List<Short> imuData = Arrays.asList(valuesBuffer.getShort(), valuesBuffer.getShort(),
        valuesBuffer.getShort(), valuesBuffer.getShort(), valuesBuffer.getShort(),
        valuesBuffer.getShort());
    int dataPointAcquisitionTimeStamp = (int) acquisitionTimestamp + (deviceLocation ==
        DeviceLocation.LEFT_EARBUD ? leftImuSamplesSinceKeyTimestamp :
        rightImuSamplesSinceKeyTimestamp) *
        Math.round(1000 / localSession.getAccelerationSampleRate());
    samples.addAcceleration(Acceleration.create(localSession.id, /*x=*/imuData.get(0),
        /*y=*/imuData.get(1), /*z=*/imuData.get(2), deviceLocation,
        /*samplingTimestamp=*/null, dataPointAcquisitionTimeStamp, receptionTimestamp));
    samples.addAngularSpeed(AngularSpeed.create(localSession.id, /*x=*/imuData.get(3),
        /*y=*/imuData.get(4), /*z=*/imuData.get(5), deviceLocation,
        /*samplingTimestamp=*/null, dataPointAcquisitionTimeStamp, receptionTimestamp));
    if (deviceLocation == DeviceLocation.LEFT_EARBUD) {
      ++leftImuSamplesSinceKeyTimestamp;
    } else {
      ++rightImuSamplesSinceKeyTimestamp;
    }
  }
}
