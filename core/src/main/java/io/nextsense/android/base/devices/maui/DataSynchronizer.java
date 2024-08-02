package io.nextsense.android.base.devices.maui;

import java.time.Duration;
import java.time.Instant;
import java.util.*;

public class DataSynchronizer {
  public static class DataPoint {
    long samplingTimestamp;
    Instant receptionTimestamp;
    float value;

    DataPoint(long samplingTimestamp, Instant receptionTimestamp, float value) {
      this.samplingTimestamp = samplingTimestamp;
      this.receptionTimestamp = receptionTimestamp;
      this.value = value;
    }

    @Override
    public boolean equals(Object obj) {
      if (this == obj) {
        return true;
      }
      if (obj == null || getClass() != obj.getClass()) {
        return false;
      }
      DataPoint other = (DataPoint) obj;
      return samplingTimestamp == other.samplingTimestamp
          && receptionTimestamp.equals(other.receptionTimestamp)
          && Float.compare(other.value, value) == 0;
    }

    @Override
    public int hashCode() {
      return Objects.hash(samplingTimestamp, receptionTimestamp, value);
    }
  }

  // If no sync was done after this long, remove data points.
  public static final Duration SYNC_TIMEOUT = Duration.ofSeconds(30);

  private final Map<String, List<DataPoint>> channelDataMap;
  private final Map<String, Duration> channelSyncPeriods;

  public DataSynchronizer(Map<String, Duration> channelSyncPeriods) {
    channelDataMap = new HashMap<>();
    this.channelSyncPeriods = new HashMap<>(channelSyncPeriods);
    for (String channel : channelSyncPeriods.keySet()) {
      channelDataMap.put(channel, new ArrayList<>());
    }
  }

  public synchronized void addData(String channel, long samplingTimestamp,
                                   Instant receptionTimestamp, float value) {
    if (!channelDataMap.containsKey(channel)) {
      throw new IllegalArgumentException("Channel does not exist: " + channel);
    }
    Objects.requireNonNull(channelDataMap.get(channel)).add(
        new DataPoint(samplingTimestamp, receptionTimestamp, value));
  }

  public synchronized List<Map<String, DataPoint>> getAllSynchronizedDataAndRemove() {
    List<Map<String, DataPoint>> synchronizedData = new ArrayList<>();
    Map<Long, Map<String, DataPoint>> timestampedData = new TreeMap<>();

    // Collect all data points by timestamp
    for (Map.Entry<String, List<DataPoint>> entry : channelDataMap.entrySet()) {
      String channel = entry.getKey();
      List<DataPoint> dataPoints = entry.getValue();

      for (DataPoint dp : dataPoints) {
        timestampedData.putIfAbsent(dp.samplingTimestamp, new HashMap<>());
        timestampedData.get(dp.samplingTimestamp).put(channel, dp);
      }
    }

    // Match the closest timestamps that are not more than the syncPeriod apart
    List<Long> timestampsToRemove = new ArrayList<>();
    for (Map.Entry<Long, Map<String, DataPoint>> entry : timestampedData.entrySet()) {
      Long timestamp = entry.getKey();
      Map<String, DataPoint> dataPointMap = entry.getValue();

      // Check if all channels are present or can be matched with nearby timestamps
      Map<String, DataPoint> synchronizedMap = new HashMap<>(dataPointMap);
      int syncSize = dataPointMap.size();
      // List<Long> conditionalTimestampsToRemove = new ArrayList<>();
      if (syncSize != channelSyncPeriods.size()) {
        for (String channel : channelSyncPeriods.keySet()) {
          if (!dataPointMap.containsKey(channel)) {
            Duration syncPeriod = channelSyncPeriods.get(channel);
            for (Map.Entry<Long, Map<String, DataPoint>> innerEntry : timestampedData.entrySet()) {
              long difference = Math.abs(innerEntry.getKey() - timestamp);
              if (difference < syncPeriod.minus(Duration.ofMillis(1)).toMillis() &&
                  innerEntry.getValue().containsKey(channel)) {
                // synchronizedMap.put(channel, innerEntry.getValue().get(channel));
                // conditionalTimestampsToRemove.add(innerEntry.getKey());
                ++syncSize;
              }
            }
          }
        }
      }

      if (syncSize == channelSyncPeriods.size()) {
        synchronizedData.add(synchronizedMap);
        timestampsToRemove.add(timestamp);
        // timestampsToRemove.addAll(conditionalTimestampsToRemove);
      }
    }

    // Remove the synchronized data points from the original channel data map
    for (String channel : channelDataMap.keySet()) {
      List<DataPoint> dataPoints = channelDataMap.get(channel);
      if (dataPoints == null) {
        continue;
      }
      dataPoints.removeIf(dp -> timestampsToRemove.contains(dp.samplingTimestamp));
    }

    // Sort the result data by sampling timestamp
    synchronizedData.sort(
        Comparator.comparing(map -> map.values().iterator().next().samplingTimestamp));

    return synchronizedData;
  }

  public synchronized List<Map<String, DataPoint>> removeOldData() {
    Map<Long, Map<String, DataPoint>> removedData = new TreeMap<>();
    for (Map.Entry<String, List<DataPoint>> entry : channelDataMap.entrySet()) {
      String channel = entry.getKey();
      Iterator<DataPoint> iterator = entry.getValue().iterator();
      while (iterator.hasNext()) {
        DataPoint dp = iterator.next();
        Instant now = Instant.now();
        if ((dp.receptionTimestamp.plus(SYNC_TIMEOUT)).isBefore(now)) {
          removedData.putIfAbsent(dp.samplingTimestamp, new HashMap<>());
          removedData.get(dp.samplingTimestamp).put(channel, dp);
          iterator.remove();
        }
      }
    }

    List<Map<String, DataPoint>> removedList = new ArrayList<>(removedData.values());
    removedList.sort(Comparator.comparing(map -> map.values().iterator().next().samplingTimestamp));

    return removedList;
  }

  public synchronized void clear() {
    for (String channel : channelDataMap.keySet()) {
      Objects.requireNonNull(channelDataMap.get(channel)).clear();
    }
  }
}