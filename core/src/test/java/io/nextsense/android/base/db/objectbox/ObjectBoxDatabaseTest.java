package io.nextsense.android.base.db.objectbox;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

import android.content.Context;

import androidx.test.core.app.ApplicationProvider;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;

import java.time.Instant;
import java.util.HashMap;
import java.util.List;

import io.nextsense.android.base.data.EegSample;

@RunWith(RobolectricTestRunner.class)
public class ObjectBoxDatabaseTest {

  private final Context context = ApplicationProvider.getApplicationContext();
  private static final HashMap<Integer, Float> SAMPLE_1_VALUES =
      new HashMap<Integer, Float>(){{put(1, 10.0f); put(2, 15.0f);}};
  private static final Instant RECEPTION_1_VALUE = Instant.ofEpochMilli(1627633663376L);
  private static final Integer RELATIVE_1_VALUE = 1;
  private static final Integer RELATIVE_2_VALUE = 2;
  private static final Integer RELATIVE_3_VALUE = 3;
  private static final Instant ABSOLUTE_1_VALUE = Instant.ofEpochMilli(1627633663370L);
  private static final int SESSION_1_VALUE = 1;
  private static final int SESSION_2_VALUE = 2;

  private ObjectBoxDatabase getDb() {
    ObjectBoxDatabase objectBoxDatabase = new ObjectBoxDatabase();
    objectBoxDatabase.init(context);
    return objectBoxDatabase;
  }

  private void putThreeEegSamples(ObjectBoxDatabase objectBoxDatabase, int sessionId) {
    putThreeEegSamples(objectBoxDatabase, sessionId, /*relativeTimeOffset=*/0);
  }

  private void putThreeEegSamples(ObjectBoxDatabase objectBoxDatabase, int sessionId,
                                  int relativeTimeOffset) {
    objectBoxDatabase.putEegSample(EegSample.create(
        sessionId, SAMPLE_1_VALUES, RECEPTION_1_VALUE, RELATIVE_1_VALUE + relativeTimeOffset,
        null));
    objectBoxDatabase.putEegSample(EegSample.create(
        sessionId, SAMPLE_1_VALUES, RECEPTION_1_VALUE, RELATIVE_2_VALUE + relativeTimeOffset,
        null));
    objectBoxDatabase.putEegSample(EegSample.create(
        sessionId, SAMPLE_1_VALUES, RECEPTION_1_VALUE, RELATIVE_3_VALUE + relativeTimeOffset,
        null));
  }

  @Test
  public void putEegSample_nullAbsoluteTimestamp_canReadBack() {
    ObjectBoxDatabase objectBoxDatabase = getDb();
    objectBoxDatabase.putEegSample(EegSample.create(
        SESSION_1_VALUE, SAMPLE_1_VALUES, RECEPTION_1_VALUE, RELATIVE_1_VALUE, null));
    List<EegSample> results = objectBoxDatabase.getEegSamples(SESSION_1_VALUE, 0, 1);
    assertEquals(1, results.size());
    EegSample sample = results.get(0);
    assertEquals(SESSION_1_VALUE, sample.getSessionId());
    assertEquals(SAMPLE_1_VALUES, sample.getEegSamples());
    assertEquals(RECEPTION_1_VALUE, sample.getReceptionTimestamp());
    assertEquals(RELATIVE_1_VALUE, sample.getRelativeSamplingTimestamp());
    assertNull(sample.getAbsoluteSamplingTimestamp());
  }

  @Test
  public void putEegSample_nullRelativeTimestamp_canReadBack() {
    ObjectBoxDatabase objectBoxDatabase = getDb();
    objectBoxDatabase.putEegSample(EegSample.create(
        SESSION_1_VALUE, SAMPLE_1_VALUES, RECEPTION_1_VALUE, null, ABSOLUTE_1_VALUE));
    List<EegSample> results = objectBoxDatabase.getEegSamples(SESSION_1_VALUE, 0, 1);
    assertEquals(1, results.size());
    EegSample sample = results.get(0);
    assertEquals(SESSION_1_VALUE, sample.getSessionId());
    assertEquals(SAMPLE_1_VALUES, sample.getEegSamples());
    assertEquals(RECEPTION_1_VALUE, sample.getReceptionTimestamp());
    assertNull(sample.getRelativeSamplingTimestamp());
    assertEquals(ABSOLUTE_1_VALUE, sample.getAbsoluteSamplingTimestamp());
  }

  @Test
  public void getEegSamples_multipleSamples_preservesOrder() {
    ObjectBoxDatabase objectBoxDatabase = getDb();
    putThreeEegSamples(objectBoxDatabase, SESSION_1_VALUE);
    List<EegSample> results = objectBoxDatabase.getEegSamples(SESSION_1_VALUE, 0, 3);
    assertEquals(3, results.size());
    assertEquals(RELATIVE_1_VALUE, results.get(0).getRelativeSamplingTimestamp());
    assertEquals(RELATIVE_2_VALUE, results.get(1).getRelativeSamplingTimestamp());
    assertEquals(RELATIVE_3_VALUE, results.get(2).getRelativeSamplingTimestamp());
  }

  @Test
  public void getEegSamples_multipleTimes_preservesOrder() {
    ObjectBoxDatabase objectBoxDatabase = getDb();
    putThreeEegSamples(objectBoxDatabase, SESSION_1_VALUE);
    List<EegSample> results = objectBoxDatabase.getEegSamples(SESSION_1_VALUE, 0, 2);
    assertEquals(2, results.size());
    assertEquals(RELATIVE_1_VALUE, results.get(0).getRelativeSamplingTimestamp());
    assertEquals(RELATIVE_2_VALUE, results.get(1).getRelativeSamplingTimestamp());
    results = objectBoxDatabase.getEegSamples(SESSION_1_VALUE, 2, 1);
    assertEquals(1, results.size());
    assertEquals(RELATIVE_3_VALUE, results.get(0).getRelativeSamplingTimestamp());
  }

  @Test
  public void getEegSamples_multipleSessions_preservesOrder() {
    ObjectBoxDatabase objectBoxDatabase = getDb();
    putThreeEegSamples(objectBoxDatabase, SESSION_1_VALUE);
    putThreeEegSamples(objectBoxDatabase, SESSION_2_VALUE, /*relativeTimeOddset=*/3);
    putThreeEegSamples(objectBoxDatabase, SESSION_1_VALUE, /*relativeTimeOddset=*/6);
    List<EegSample> results = objectBoxDatabase.getEegSamples(SESSION_1_VALUE, 0, 6);
    assertEquals(6, results.size());
    assertEquals(RELATIVE_1_VALUE, results.get(0).getRelativeSamplingTimestamp());
    assertEquals(RELATIVE_2_VALUE, results.get(1).getRelativeSamplingTimestamp());
    assertEquals(RELATIVE_3_VALUE, results.get(2).getRelativeSamplingTimestamp());
    assertEquals((Integer)7, results.get(3).getRelativeSamplingTimestamp());
    assertEquals((Integer)8, results.get(4).getRelativeSamplingTimestamp());
    assertEquals((Integer)9, results.get(5).getRelativeSamplingTimestamp());
    results = objectBoxDatabase.getEegSamples(SESSION_2_VALUE, 0, 3);
    assertEquals(3, results.size());
    assertEquals((Integer)4, results.get(0).getRelativeSamplingTimestamp());
    assertEquals((Integer)5, results.get(1).getRelativeSamplingTimestamp());
    assertEquals((Integer)6, results.get(2).getRelativeSamplingTimestamp());
  }

  @Test
  public void getEegSamples_countOverSize_returnsUntilEnd() {
    ObjectBoxDatabase objectBoxDatabase = getDb();
    putThreeEegSamples(objectBoxDatabase, SESSION_1_VALUE);
    List<EegSample> results = objectBoxDatabase.getEegSamples(SESSION_1_VALUE, 2, 3);
    assertEquals(1, results.size());
  }

  @Test
  public void getEegSamples_offsetOverSize_returnsEmpty() {
    ObjectBoxDatabase objectBoxDatabase = getDb();
    putThreeEegSamples(objectBoxDatabase, SESSION_1_VALUE);
    List<EegSample> results = objectBoxDatabase.getEegSamples(SESSION_1_VALUE, 3, 1);
    assertTrue(results.isEmpty());
  }

  @Test
  public void getEegSamples_wrongSessionId_returnsEmpty() {
    ObjectBoxDatabase objectBoxDatabase = getDb();
    objectBoxDatabase.putEegSample(EegSample.create(
        SESSION_1_VALUE, SAMPLE_1_VALUES, RECEPTION_1_VALUE, RELATIVE_1_VALUE, null));
    List<EegSample> results = objectBoxDatabase.getEegSamples(SESSION_2_VALUE, 0, 1);
    assertEquals(0, results.size());
  }

  @Test
  public void getLastEegSamples_returnsCorrectValues() {
    ObjectBoxDatabase objectBoxDatabase = getDb();
    putThreeEegSamples(objectBoxDatabase, SESSION_1_VALUE);
    List<EegSample> results = objectBoxDatabase.getLastEegSamples(SESSION_1_VALUE, 2);
    assertEquals(2, results.size());
    assertEquals(RELATIVE_2_VALUE, results.get(0).getRelativeSamplingTimestamp());
    assertEquals(RELATIVE_3_VALUE, results.get(1).getRelativeSamplingTimestamp());
  }

  @Test
  public void getLastEegSamples_countSuperiorToSize_returnsAllValues() {
    ObjectBoxDatabase objectBoxDatabase = getDb();
    putThreeEegSamples(objectBoxDatabase, SESSION_1_VALUE);
    List<EegSample> results = objectBoxDatabase.getLastEegSamples(SESSION_1_VALUE, 4);
    assertEquals(3, results.size());
  }

  @Test
  public void deleteSessionData_rightSession_deletesEntries() {
    ObjectBoxDatabase objectBoxDatabase = getDb();
    putThreeEegSamples(objectBoxDatabase, SESSION_2_VALUE);
    assertEquals(3, objectBoxDatabase.deleteEegSamplesData(SESSION_2_VALUE));
    assertTrue(objectBoxDatabase.getEegSamples(SESSION_2_VALUE).isEmpty());
  }

  @Test
  public void deleteSessionData_wrongSession_doNotDeletesEntries() {
    ObjectBoxDatabase objectBoxDatabase = getDb();
    putThreeEegSamples(objectBoxDatabase, SESSION_2_VALUE);
    assertEquals(0, objectBoxDatabase.deleteEegSamplesData(SESSION_1_VALUE));
    assertEquals(3, objectBoxDatabase.getEegSamples(SESSION_2_VALUE).size());
  }
}
