package io.nextsense.android.base.db.memory;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.nextsense.android.base.data.Acceleration;
import io.nextsense.android.base.data.AngularSpeed;
import io.nextsense.android.base.data.EegSample;
import io.nextsense.android.base.data.Samples;
import io.nextsense.android.base.utils.EvictingArray;

/**
 * Memory cache for recent data for performance.
 */
public class MemoryCache {
  // 250 samples per second times 60 seconds times 12 minutes.
  private static final int DEFAULT_RETENTION_SAMPLES = 250 * 60 * 12;

  private final Map<String, EvictingArray<Float>> eegChannels = new HashMap<>();
  private final Map<String, EvictingArray<Integer>> imuChannels = new HashMap<>();
  private final EvictingArray<Long> timestamps;
  private final Object eegLock = new Object();
  private final Object imuLock = new Object();

  private MemoryCache() {
    timestamps = new EvictingArray<>(DEFAULT_RETENTION_SAMPLES);
  }

  private MemoryCache(List<String> eegChannelNames, List<String> imuChannelNames) {
    for (String eegChannelName : eegChannelNames) {
      eegChannels.put(eegChannelName, new EvictingArray<>(DEFAULT_RETENTION_SAMPLES));
    }
    for (String imuChannelName : imuChannelNames) {
      imuChannels.put(imuChannelName, new EvictingArray<>(DEFAULT_RETENTION_SAMPLES));
    }
    timestamps = new EvictingArray<>(DEFAULT_RETENTION_SAMPLES);
  }

  public static MemoryCache create() {
    return new MemoryCache();
  }

  public static MemoryCache create(List<String> eegChannelNames, List<String> imuChannelNames) {
    return new MemoryCache(eegChannelNames, imuChannelNames);
  }
  public void init(List<String> eegChannelNames, List<String> imuChannelNames) {
    eegChannels.clear();
    for (String eegChannelName : eegChannelNames) {
      eegChannels.put(eegChannelName, new EvictingArray<>(DEFAULT_RETENTION_SAMPLES));
    }
    imuChannels.clear();
    for (String imuChannelName : imuChannelNames) {
      imuChannels.put(imuChannelName, new EvictingArray<>(DEFAULT_RETENTION_SAMPLES));
    }
    timestamps.clear();
  }

  public void addChannelData(Samples samples) {
    synchronized (eegLock) {
      for (EegSample eegSample : samples.getEegSamples()) {
        long timestamp = eegSample.getAbsoluteSamplingTimestamp() != null ?
            eegSample.getAbsoluteSamplingTimestamp().toEpochMilli() :
            eegSample.getRelativeSamplingTimestamp();
        timestamps.addValue(timestamp);
        for (Integer eegChannelNumber : eegSample.getEegSamples().keySet()) {
          String channelName = String.valueOf(eegChannelNumber);
          eegChannels.get(channelName).addValue(
              eegSample.getEegSamples().get(eegChannelNumber));
        }
      }
    }
    synchronized (imuLock) {
      for (Acceleration acceleration : samples.getAccelerations()) {
        switch (acceleration.getDeviceLocation()) {
          case BOX:
            imuChannels.get(Acceleration.Channels.ACC_X.getName()).addValue(acceleration.getX());
            imuChannels.get(Acceleration.Channels.ACC_Y.getName()).addValue(acceleration.getY());
            imuChannels.get(Acceleration.Channels.ACC_Z.getName()).addValue(acceleration.getZ());
            break;
          case LEFT_EARBUD:
            imuChannels.get(Acceleration.Channels.ACC_L_X.getName()).addValue(
                acceleration.getLeftX());
            imuChannels.get(Acceleration.Channels.ACC_L_Y.getName()).addValue(
                acceleration.getLeftY());
            imuChannels.get(Acceleration.Channels.ACC_L_Z.getName()).addValue(
                acceleration.getLeftZ());
            break;
          case RIGHT_EARBUD:
            imuChannels.get(Acceleration.Channels.ACC_R_X.getName()).addValue(
                acceleration.getRightX());
            imuChannels.get(Acceleration.Channels.ACC_R_Y.getName()).addValue(
                acceleration.getRightY());
            imuChannels.get(Acceleration.Channels.ACC_R_Z.getName()).addValue(
                acceleration.getRightZ());
            break;
          default:
            throw new IllegalArgumentException("Unknown device location: " +
                acceleration.getDeviceLocation());
        }
      }
      for (AngularSpeed angularSpeed : samples.getAngularSpeeds()) {
        switch (angularSpeed.getDeviceLocation()) {
          case BOX:
            imuChannels.get(AngularSpeed.Channels.GYRO_X.getName()).addValue(angularSpeed.getX());
            imuChannels.get(AngularSpeed.Channels.GYRO_Y.getName()).addValue(angularSpeed.getY());
            imuChannels.get(AngularSpeed.Channels.GYRO_Z.getName()).addValue(angularSpeed.getZ());
            break;
          case LEFT_EARBUD:
            imuChannels.get(AngularSpeed.Channels.GYRO_L_X.getName()).addValue(
                angularSpeed.getLeftX());
            imuChannels.get(AngularSpeed.Channels.GYRO_L_Y.getName()).addValue(
                angularSpeed.getLeftY());
            imuChannels.get(AngularSpeed.Channels.GYRO_L_Z.getName()).addValue(
                angularSpeed.getLeftZ());
            break;
          case RIGHT_EARBUD:
            imuChannels.get(AngularSpeed.Channels.GYRO_R_X.getName()).addValue(
                angularSpeed.getRightX());
            imuChannels.get(AngularSpeed.Channels.GYRO_R_Y.getName()).addValue(
                angularSpeed.getRightY());
            imuChannels.get(AngularSpeed.Channels.GYRO_R_Z.getName()).addValue(
                angularSpeed.getRightZ());
            break;
          default:
            throw new IllegalArgumentException("Unknown device location: " +
                angularSpeed.getDeviceLocation());
        }
      }
    }
  }

  public List<Float> getLastEegChannelData(String channelName, int numberOfSamples) {
    if (!eegChannels.containsKey(channelName)) {
      throw new IllegalArgumentException("channel " + channelName + " does not exists.");
    }
    synchronized (eegLock) {
      return eegChannels.get(channelName).getLastValues(numberOfSamples);
    }
  }

  public List<Integer> getLastImuChannelData(String channelName, int numberOfSamples) {
    if (!imuChannels.containsKey(channelName)) {
      throw new IllegalArgumentException("channel " + channelName + " does not exists.");
    }
    synchronized (imuLock) {
      return imuChannels.get(channelName).getLastValues(numberOfSamples);
    }
  }

  public List<Long> getLastTimestamps(int numberOfSamples) {
    synchronized (eegLock) {
      return timestamps.getLastValues(numberOfSamples);
    }
  }

  public void clear() {
    synchronized (eegLock) {
      for (EvictingArray<Float> array : eegChannels.values()) {
        array.clear();
      }
    }
    synchronized (imuLock) {
      for (EvictingArray<Integer> array : imuChannels.values()) {
        array.clear();
      }
    }
    synchronized (eegLock) {
      timestamps.clear();
    }
  }
}
