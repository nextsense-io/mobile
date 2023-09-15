package io.nextsense.android.base.db.memory;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.nextsense.android.base.data.Acceleration;
import io.nextsense.android.base.data.EegSample;
import io.nextsense.android.base.data.Samples;
import io.nextsense.android.base.utils.EvictingArray;

/**
 * Memory cache for recent data for performance.
 */
public class MemoryCache {
  // 250 samples per second times 60 seconds times 5 minutes.
  private static final int DEFAULT_RETENTION_SAMPLES = 250 * 60 * 5;

  private final Map<String, EvictingArray<Float>> eegChannels = new HashMap<>();
  private final Map<String, EvictingArray<Integer>> accChannels = new HashMap<>();
  private final EvictingArray<Long> timestamps;
  private final Object eegLock = new Object();
  private final Object accLock = new Object();

  private MemoryCache() {
    timestamps = new EvictingArray<>(DEFAULT_RETENTION_SAMPLES);
  }

  private MemoryCache(List<String> eegChannelNames, List<String> accChannelNames) {
    for (String eegChannelName : eegChannelNames) {
      eegChannels.put(eegChannelName, new EvictingArray<>(DEFAULT_RETENTION_SAMPLES));
    }
    for (String accChannelName : accChannelNames) {
      accChannels.put(accChannelName, new EvictingArray<>(DEFAULT_RETENTION_SAMPLES));
    }
    timestamps = new EvictingArray<>(DEFAULT_RETENTION_SAMPLES);
  }

  public static MemoryCache create() {
    return new MemoryCache();
  }

  public static MemoryCache create(List<String> eegChannelNames, List<String> accChannelNames) {
    return new MemoryCache(eegChannelNames, accChannelNames);
  }
  public void init(List<String> eegChannelNames, List<String> accChannelNames) {
    eegChannels.clear();
    for (String eegChannelName : eegChannelNames) {
      eegChannels.put(eegChannelName, new EvictingArray<>(DEFAULT_RETENTION_SAMPLES));
    }
    accChannels.clear();
    for (String accChannelName : accChannelNames) {
      accChannels.put(accChannelName, new EvictingArray<>(DEFAULT_RETENTION_SAMPLES));
    }
    timestamps.clear();
  }

  public void addChannelData(Samples samples) {
    synchronized (eegLock) {
      for (EegSample eegSample : samples.getEegSamples()) {
        timestamps.addValue(eegSample.getAbsoluteSamplingTimestamp().toEpochMilli());
        for (Integer eegChannelNumber : eegSample.getEegSamples().keySet()) {
          String channelName = String.valueOf(eegChannelNumber);
          eegChannels.get(channelName).addValue(
              eegSample.getEegSamples().get(eegChannelNumber));
        }
      }
    }
    synchronized (accLock) {
      for (Acceleration acceleration : samples.getAccelerations()) {
        accChannels.get("x").addValue(acceleration.getX());
        accChannels.get("y").addValue(acceleration.getY());
        accChannels.get("z").addValue(acceleration.getZ());
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

  public List<Integer> getLastAccChannelData(String channelName, int numberOfSamples) {
    if (!accChannels.containsKey(channelName)) {
      throw new IllegalArgumentException("channel " + channelName + " does not exists.");
    }
    synchronized (accLock) {
      return accChannels.get(channelName).getLastValues(numberOfSamples);
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
    synchronized (accLock) {
      for (EvictingArray<Integer> array : accChannels.values()) {
        array.clear();
      }
    }
    synchronized (eegLock) {
      timestamps.clear();
    }
  }
}
