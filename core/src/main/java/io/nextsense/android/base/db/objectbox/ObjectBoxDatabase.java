package io.nextsense.android.base.db.objectbox;

import android.content.Context;

import java.util.List;

import io.nextsense.android.base.data.Acceleration;
import io.nextsense.android.base.data.Acceleration_;
import io.nextsense.android.base.data.EegSample;
import io.nextsense.android.base.data.EegSample_;
import io.nextsense.android.base.data.MyObjectBox;
import io.nextsense.android.base.db.Database;
import io.objectbox.Box;
import io.objectbox.BoxStore;
import io.objectbox.query.Query;

/**
 * Naturally ordered object database.
 */
public class ObjectBoxDatabase implements Database {

  private BoxStore boxStore;
  private Box<EegSample> eegSampleBox;
  private Box<Acceleration> accelerationBox;
  private Query<EegSample> eegSamplesQuery;
  private Query<Acceleration> accelerationQuery;

  @Override
  public void init(Context context) {
    boxStore = MyObjectBox.builder().androidContext(context.getApplicationContext()).build();
    eegSampleBox = boxStore.boxFor(EegSample.class);
    eegSamplesQuery = eegSampleBox.query().equal(EegSample_.sessionId, 0).build();
    accelerationBox = boxStore.boxFor(Acceleration.class);
    accelerationQuery = accelerationBox.query().equal(Acceleration_.sessionId, 0).build();
  }

  public long putEegSample(EegSample eegSample) {
    return eegSampleBox.put(eegSample);
  }

  public long putAcceleration(Acceleration acceleration) {
    return accelerationBox.put(acceleration);
  }

  public List<EegSample> getEegSamples(int sessionId) {
    return eegSamplesQuery.setParameter(EegSample_.sessionId, sessionId).find();
  }

  public List<Acceleration> getAccelerations(int sessionId) {
    return accelerationQuery.setParameter(Acceleration_.sessionId, sessionId).find();
  }

  public List<EegSample> getLastEegSamples(int sessionId, long count) {
    long offset = count <= eegSampleBox.count()? eegSampleBox.count() - count: 0;
    return getEegSamples(sessionId, offset, count);
  }

  public List<Acceleration> getLastAccelerations(int sessionId, long count) {
    long offset = count <= accelerationBox.count()? accelerationBox.count() - count: 0;
    return getAccelerations(sessionId, offset, count);
  }

  public List<EegSample> getEegSamples(int sessionId, long offset, long count) {
    return eegSamplesQuery.setParameter(EegSample_.sessionId, sessionId).find(offset, count);
  }

  public List<Acceleration> getAccelerations(int sessionId, long offset, long count) {
    return accelerationQuery.setParameter(Acceleration_.sessionId, sessionId).find(offset, count);
  }

  public long deleteEegSamplesData(int sessionId) {
    return eegSamplesQuery.setParameter(EegSample_.sessionId, sessionId).remove();
  }

  public long deleteAccelerationData(int sessionId) {
    return accelerationQuery.setParameter(Acceleration_.sessionId, sessionId).remove();
  }
}
