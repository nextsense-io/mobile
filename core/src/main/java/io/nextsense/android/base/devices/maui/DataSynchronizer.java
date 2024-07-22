package io.nextsense.android.base.devices.maui;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Objects;

public class DataSynchronizer {
  static class DataPoint {
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
  }

  private final Map<String, List<DataPoint>> channelDataMap;

  public DataSynchronizer(List<String> channels) {
    channelDataMap = new HashMap<>();
    for (String channel : channels) {
      channelDataMap.put(channel, new ArrayList<>());
    }
  }

  public synchronized void addData(
      String channel, long samplingTimestamp, Instant receptionTimestamp, float value) {
    if (!channelDataMap.containsKey(channel)) {
      throw new IllegalArgumentException("Channel does not exist: " + channel);
    }
    Objects.requireNonNull(channelDataMap.get(channel)).add(
        new DataPoint(samplingTimestamp, receptionTimestamp, value));
  }

  public synchronized List<Map<String, DataPoint>> getAllSynchronizedDataAndRemove() {
    List<Map<String, DataPoint>> synchronizedData = new ArrayList<>();
    Map<Long, Map<String, DataPoint>> timestampedData = new HashMap<>();

    // Collect all data points by timestamp
    for (Map.Entry<String, List<DataPoint>> entry : channelDataMap.entrySet()) {
      String channel = entry.getKey();
      List<DataPoint> dataPoints = entry.getValue();

      for (DataPoint dp : dataPoints) {
        timestampedData.putIfAbsent(dp.samplingTimestamp, new HashMap<>());
        timestampedData.get(dp.samplingTimestamp).put(channel, dp);
      }
    }

    // Filter out timestamps that do not have data for all channels
    Long lastTimestamp = 0L;
    Iterator<Map.Entry<Long, Map<String, DataPoint>>> iterator =
        timestampedData.entrySet().iterator();
    while (iterator.hasNext()) {
      Map.Entry<Long, Map<String, DataPoint>> entry = iterator.next();
      if (entry.getValue().size() == channelDataMap.size()) {
        synchronizedData.add(entry.getValue());
        iterator.remove(); // Remove from timestampedData to indicate it's processed
        if (entry.getKey() > lastTimestamp) {
          lastTimestamp = entry.getKey();
        }
      }
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
}
