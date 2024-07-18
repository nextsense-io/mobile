package io.nextsense.android.base.devices.maui;

import org.junit.Before;
import org.junit.Test;

import java.time.Instant;
import java.util.*;

import static org.junit.Assert.*;

public class DataSynchronizerTest {
  private DataSynchronizer dataSynchronizer;

  @Before
  public void setUp() {
    List<String> channels = Arrays.asList("channel1", "channel2", "channel3");
    dataSynchronizer = new DataSynchronizer(channels);
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
}
