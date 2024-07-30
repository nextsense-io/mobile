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
  public static final Duration SYNC_TIMEOUT = Duration.ofSeconds(6);

  private final Map<String, List<DataPoint>> channelDataMap;
  private final Duration syncPeriod;

  public DataSynchronizer(List<String> channels, float samplingRate) {
    channelDataMap = new HashMap<>();
    for (String channel : channels) {
      channelDataMap.put(channel, new ArrayList<>());
    }
    syncPeriod = Duration.ofMillis(Math.round(1000 / samplingRate));
  }

  public synchronized void addData(String channel, long samplingTimestamp, Instant receptionTimestamp, float value) {
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
    Long lastTimestamp = 0L;
    Iterator<Map.Entry<Long, Map<String, DataPoint>>> iterator = timestampedData.entrySet().iterator();
    while (iterator.hasNext()) {
      Map.Entry<Long, Map<String, DataPoint>> entry = iterator.next();
      Long timestamp = entry.getKey();

      if (entry.getValue().size() == channelDataMap.size()) {
        synchronizedData.add(entry.getValue());
        timestampsToRemove.add(timestamp);
        if (timestamp > lastTimestamp) {
          lastTimestamp = timestamp;
        }
      } else {
        for (Map.Entry<Long, Map<String, DataPoint>> innerEntry : timestampedData.entrySet()) {
          if (!innerEntry.getKey().equals(timestamp) &&
              Math.abs(innerEntry.getKey() - timestamp) <= syncPeriod.toMillis()) {
            entry.getValue().putAll(innerEntry.getValue());
            if (entry.getValue().size() == channelDataMap.size()) {
              synchronizedData.add(entry.getValue());
              timestampsToRemove.add(timestamp);
              timestampsToRemove.add(innerEntry.getKey());
              if (timestamp > lastTimestamp) {
                lastTimestamp = timestamp;
              }
              break;
            }
          }
        }
      }
    }

    // Remove the processed timestamps from timestampedData
    for (Long timestamp : timestampsToRemove) {
      timestampedData.remove(timestamp);
    }

    // Remove the synchronized data points from the original channel data map
    final long finalLastTimestamp = lastTimestamp;
    for (String channel : channelDataMap.keySet()) {
      List<DataPoint> dataPoints = channelDataMap.get(channel);
      if (dataPoints == null) {
        continue;
      }
      dataPoints.removeIf(dp -> dp.samplingTimestamp <= finalLastTimestamp);
    }

    // Sort the result data by sampling timestamp
    synchronizedData.sort(Comparator.comparing(map -> map.values().iterator().next().samplingTimestamp));

    return synchronizedData;
  }

  public synchronized List<Map<String, DataPoint>> removeOldData() {
    Map<Long, Map<String, DataPoint>> removedData = new TreeMap<>();
    for (Map.Entry<String, List<DataPoint>> entry : channelDataMap.entrySet()) {
      String channel = entry.getKey();
      Iterator<DataPoint> iterator = entry.getValue().iterator();
      while (iterator.hasNext()) {
        DataPoint dp = iterator.next();
        if (dp.receptionTimestamp.plus(SYNC_TIMEOUT).isBefore(Instant.now())) {
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
