package io.nextsense.android.base.devices.maui;

import org.junit.Before;
import org.junit.Test;

import java.time.Duration;
import java.time.Instant;
import java.util.*;

import static org.junit.Assert.*;

public class DataSynchronizerTest {
  private DataSynchronizer dataSynchronizer;

  @Before
  public void setUp() {
    Map<String, Duration> channelSyncPeriods = new HashMap<>();
    channelSyncPeriods.put("channel1", Duration.ofSeconds(1)); // 1 second
    channelSyncPeriods.put("channel2", Duration.ofSeconds(2)); // 2 seconds
    channelSyncPeriods.put("channel3", Duration.ofMillis(500)); // 0.5 second

    dataSynchronizer = new DataSynchronizer(channelSyncPeriods);
  }

  @Test
  public void testAddDataAndGetAllSynchronizedDataAndRemove() {
    dataSynchronizer.addData("channel1", 1627550710000L, Instant.ofEpochMilli(1627550710000L),
        1.0f);
    dataSynchronizer.addData("channel2", 1627550710000L, Instant.ofEpochMilli(1627550710000L),
        2.0f);
    dataSynchronizer.addData("channel3", 1627550710000L, Instant.ofEpochMilli(1627550710000L),
        3.0f);

    dataSynchronizer.addData("channel1", 1627550720000L, Instant.ofEpochMilli(1627550710000L),
        1.1f);
    dataSynchronizer.addData("channel2", 1627550720000L, Instant.ofEpochMilli(1627550710000L),
        2.1f);

    dataSynchronizer.addData("channel1", 1627550730000L, Instant.ofEpochMilli(1627550710000L),
        1.2f);
    dataSynchronizer.addData("channel2", 1627550730000L, Instant.ofEpochMilli(1627550710000L),
        2.2f);
    dataSynchronizer.addData("channel3", 1627550730000L, Instant.ofEpochMilli(1627550710000L),
        3.2f);

    List<Map<String, DataSynchronizer.DataPoint>> allSynchronizedData =
        dataSynchronizer.getAllSynchronizedDataAndRemove();

    List<Map<String, DataSynchronizer.DataPoint>> expectedData = new ArrayList<>();
    Map<String, DataSynchronizer.DataPoint> dataPoint1 = new HashMap<>();
    dataPoint1.put("channel1", new DataSynchronizer.DataPoint(1627550710000L,
        Instant.ofEpochMilli(1627550710000L), 1.0f));
    dataPoint1.put("channel2", new DataSynchronizer.DataPoint(1627550710000L,
        Instant.ofEpochMilli(1627550710000L), 2.0f));
    dataPoint1.put("channel3", new DataSynchronizer.DataPoint(1627550710000L,
        Instant.ofEpochMilli(1627550710000L), 3.0f));

    Map<String, DataSynchronizer.DataPoint> dataPoint2 = new HashMap<>();
    dataPoint2.put("channel1", new DataSynchronizer.DataPoint(1627550730000L,
        Instant.ofEpochMilli(1627550710000L), 1.2f));
    dataPoint2.put("channel2", new DataSynchronizer.DataPoint(1627550730000L,
        Instant.ofEpochMilli(1627550710000L),2.2f));
    dataPoint2.put("channel3", new DataSynchronizer.DataPoint(1627550730000L,
        Instant.ofEpochMilli(1627550710000L),3.2f));

    expectedData.add(dataPoint1);
    expectedData.add(dataPoint2);

    assertEquals(expectedData, allSynchronizedData);
  }

  @Test
  public void testAddDataThrowsExceptionForNonexistentChannel() {
    try {
      dataSynchronizer.addData("nonexistentChannel", 1627550710000L,
          Instant.ofEpochMilli(1627550710000L), 1.0f);
      fail("Expected IllegalArgumentException to be thrown");
    } catch (IllegalArgumentException e) {
      assertEquals("Channel does not exist: nonexistentChannel", e.getMessage());
    }
  }

  @Test
  public void testGetAllSynchronizedDataAndRemoveEmptyData() {
    List<Map<String, DataSynchronizer.DataPoint>> allSynchronizedData =
        dataSynchronizer.getAllSynchronizedDataAndRemove();
    assertTrue(allSynchronizedData.isEmpty());
  }

  @Test
  public void testSynchronizedDataIsRemoved() {
    dataSynchronizer.addData("channel1", 1627550710000L, Instant.ofEpochMilli(1627550710000L),
        1.0f);
    dataSynchronizer.addData("channel2", 1627550710000L, Instant.ofEpochMilli(1627550710000L),
        2.0f);
    dataSynchronizer.addData("channel3", 1627550710000L, Instant.ofEpochMilli(1627550710000L),
        3.0f);

    List<Map<String, DataSynchronizer.DataPoint>> allSynchronizedData =
        dataSynchronizer.getAllSynchronizedDataAndRemove();
    assertEquals(1, allSynchronizedData.size());

    // Fetch again to check if the data is removed
    allSynchronizedData = dataSynchronizer.getAllSynchronizedDataAndRemove();
    assertTrue(allSynchronizedData.isEmpty());
  }

  @Test
  public void testEquals() {
    DataSynchronizer.DataPoint dataPoint1 = new DataSynchronizer.DataPoint(1627550710000L,
        Instant.ofEpochMilli(1627550710000L), 1.0f);
    DataSynchronizer.DataPoint dataPoint2 = new DataSynchronizer.DataPoint(1627550710000L,
        Instant.ofEpochMilli(1627550710000L), 1.0f);
    DataSynchronizer.DataPoint dataPoint3 = new DataSynchronizer.DataPoint(1627550710000L,
        Instant.ofEpochMilli(1627550710000L), 2.0f);

    assertEquals(dataPoint1, dataPoint2);
    assertNotEquals(dataPoint1, dataPoint3);
  }

  @Test
  public void testEqualsWithDifferentObject() {
    DataSynchronizer.DataPoint dataPoint = new DataSynchronizer.DataPoint(1627550710000L,
        Instant.ofEpochMilli(1627550710000L), 1.0f);
    assertNotEquals(dataPoint, new Object());
  }

  @Test
  public void testRemoveOldData() {
    Instant twentySecondAgo = Instant.now().minusSeconds(20);
    dataSynchronizer.addData("channel1", 1627550710000L, twentySecondAgo,
        1.0f);
    dataSynchronizer.addData("channel2", 1627550710000L, twentySecondAgo,
        2.0f);
    dataSynchronizer.addData("channel3", 1627550710000L, twentySecondAgo,
        3.0f);

    dataSynchronizer.addData("channel1", 1627550720000L, twentySecondAgo,
        1.1f);
    dataSynchronizer.addData("channel2", 1627550720000L, twentySecondAgo,
        2.1f);

    dataSynchronizer.addData("channel1", 1627550730000L, Instant.now(),
        1.2f);
    dataSynchronizer.addData("channel2", 1627550730000L, Instant.now(),
        2.2f);
    dataSynchronizer.addData("channel3", 1627550730000L, Instant.now(),
        3.2f);

    dataSynchronizer.removeOldData();

    List<Map<String, DataSynchronizer.DataPoint>> allSynchronizedData =
        dataSynchronizer.getAllSynchronizedDataAndRemove();
    assertEquals(1, allSynchronizedData.size());
  }

  @Test
  public void testMatchingBasedOnNearbyTimestamp() {
    Instant now = Instant.now();

    dataSynchronizer.addData("channel1", 1627550710000L, now, 1.0f);
    dataSynchronizer.addData("channel2", 1627550710500L, now, 2.0f); // 500ms later
    dataSynchronizer.addData("channel3", 1627550710900L, now, 3.0f); // 400ms after channel2

    List<Map<String, DataSynchronizer.DataPoint>> allData = dataSynchronizer.getAllSynchronizedDataAndRemove();

    List<Map<String, DataSynchronizer.DataPoint>> expectedData = new ArrayList<>();
    Map<String, DataSynchronizer.DataPoint> dataPoint = new HashMap<>();
    dataPoint.put("channel1", new DataSynchronizer.DataPoint(1627550710000L, now, 1.0f));
    dataPoint.put("channel2", new DataSynchronizer.DataPoint(1627550710500L, now, 2.0f));
    dataPoint.put("channel3", new DataSynchronizer.DataPoint(1627550710900L, now, 3.0f));
    expectedData.add(dataPoint);

    assertTrue(allData.containsAll(expectedData));
  }
}