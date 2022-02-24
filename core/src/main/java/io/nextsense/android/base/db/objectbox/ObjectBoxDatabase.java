package io.nextsense.android.base.db.objectbox;

import android.content.Context;
import android.util.Log;

import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import io.nextsense.android.base.data.Acceleration;
import io.nextsense.android.base.data.Acceleration_;
import io.nextsense.android.base.data.BaseRecord;
import io.nextsense.android.base.data.DeviceState;
import io.nextsense.android.base.data.EegSample;
import io.nextsense.android.base.data.EegSample_;
import io.nextsense.android.base.data.LocalSession;
import io.nextsense.android.base.data.LocalSession_;
import io.nextsense.android.base.data.MyObjectBox;
import io.nextsense.android.base.db.Database;
import io.objectbox.Box;
import io.objectbox.BoxStore;
import io.objectbox.query.Query;
import io.objectbox.reactive.DataObserver;
import io.objectbox.reactive.DataSubscription;
import io.objectbox.reactive.Scheduler;

/**
 * Naturally ordered object database.
 */
public class ObjectBoxDatabase implements Database {
  private static final String TAG = ObjectBoxDatabase.class.getSimpleName();

  private BoxStore boxStore;
  private Box<LocalSession> localSessionBox;
  private Box<EegSample> eegSampleBox;
  private Box<Acceleration> accelerationBox;
  private Box<DeviceState> deviceStateBox;
  private Query<LocalSession> activeSessionQuery;
  private Query<LocalSession> sessionFinishedQuery;
  private Query<EegSample> eegSamplesQuery;
  private Query<Acceleration> accelerationQuery;

  @Override
  public void init(Context context) {
    boxStore = MyObjectBox.builder().androidContext(context.getApplicationContext()).build();
    localSessionBox = boxStore.boxFor(LocalSession.class);
    activeSessionQuery = localSessionBox.query().equal(
        LocalSession_.status, LocalSession.Status.RECORDING.id).build();
    sessionFinishedQuery = localSessionBox.query().equal(LocalSession_.id, 0)
        .equal(LocalSession_.status, LocalSession.Status.FINISHED.id).build();
    eegSampleBox = boxStore.boxFor(EegSample.class);
    eegSamplesQuery = eegSampleBox.query().equal(EegSample_.localSessionId, 0).build();
    accelerationBox = boxStore.boxFor(Acceleration.class);
    accelerationQuery = accelerationBox.query().equal(Acceleration_.localSessionId, 0).build();
    deviceStateBox = boxStore.boxFor(DeviceState.class);
    Log.d(TAG, "Size on disk: " + boxStore.sizeOnDisk());
    Log.d(TAG, boxStore.diagnose());
  }

  public void stop() {
    boxStore.closeThreadResources();
    boxStore.close();
  }

  public void runInTx(Runnable runnable) {
    boxStore.runInTx(runnable);
  }

  public <T extends BaseRecord> DataSubscription subscribe(
      Class<T> type, DataObserver<Class<T>> dataObserver, Scheduler scheduler) {
    return boxStore.subscribe(type).on(scheduler).observer(dataObserver);
  }

  public Query<LocalSession> getFinishedLocalSession(long localSessionId) {
    return sessionFinishedQuery.setParameter(LocalSession_.id, localSessionId);
  }

  public long putLocalSession(LocalSession localSession) {
    return localSessionBox.put(localSession);
  }

  public long putEegSample(EegSample eegSample) {
    return eegSampleBox.put(eegSample);
  }

  public long putAcceleration(Acceleration acceleration) {
    return accelerationBox.put(acceleration);
  }

  public long putDeviceState(DeviceState deviceState) {
    return deviceStateBox.put(deviceState);
  }

  public LocalSession getLocalSession(int localSessionId) {
    return localSessionBox.get(localSessionId);
  }

  public List<LocalSession> getLocalSessions() {
    return localSessionBox.getAll();
  }

  public Optional<LocalSession> getActiveSession() {
    List<LocalSession> activeSessions = activeSessionQuery.find();
    if (activeSessions.size() > 1) {
      Log.w(TAG, "More than one active session");
    }
    if (!activeSessions.isEmpty()) {
      return Optional.of(activeSessions.get(activeSessions.size() - 1));
    }
    return Optional.empty();
  }

  public List<EegSample> getEegSamples(int localSessionId) {
    return eegSamplesQuery.setParameter(EegSample_.localSessionId, localSessionId).find();
  }

  public List<Acceleration> getAccelerations(int localSessionId) {
    return accelerationQuery.setParameter(Acceleration_.localSessionId, localSessionId).find();
  }

  public List<EegSample> getLastEegSamples(int localSessionId, long count) {
    long sessionEegSamplesCount = getEegSamplesCount(localSessionId);
    long offset = count <= sessionEegSamplesCount ? sessionEegSamplesCount - count: 0;
    return getEegSamples(localSessionId, offset, count);
  }

  public List<Float> getLastChannelData(int localSessionId, int channelNumber, Duration duration) {
    LocalSession localSession = getLocalSession(localSessionId);
    float seconds = duration.toMillis() / 1000.0f;
    List<EegSample> eegSamples = getLastEegSamples(localSessionId,
        Math.round(Math.floor(seconds * localSession.getEegSampleRate())));
    List<Float> channelSamples = new ArrayList<>(eegSamples.size());
    for (EegSample eegSample : eegSamples) {
      channelSamples.add(eegSample.getEegSamples().get(channelNumber));
    }
    return channelSamples;
  }

  public long getEegSamplesCount(long localSessionId) {
    return eegSamplesQuery.setParameter(EegSample_.localSessionId, localSessionId).count();
  }

  public List<Acceleration> getLastAccelerations(int localSessionId, long count) {
    long sessionAccelerationCount = getAccelerationCount(localSessionId);
    long offset = count <= sessionAccelerationCount ? sessionAccelerationCount - count: 0;
    return getAccelerations(localSessionId, offset, count);
  }

  public List<EegSample> getEegSamples(long localSessionId, long offset, long count) {
    return eegSamplesQuery.setParameter(EegSample_.localSessionId, localSessionId).
        find(offset, count);
  }

  public List<Acceleration> getAccelerations(int localSessionId, long offset, long count) {
    return accelerationQuery.setParameter(Acceleration_.localSessionId, localSessionId).
        find(offset, count);
  }

  public long getAccelerationCount() {
    return accelerationBox.count();
  }

  public long getAccelerationCount(long localSessionId) {
    return accelerationQuery.setParameter(Acceleration_.localSessionId, localSessionId).count();
  }

  public boolean deleteLocalSession(long localSessionId) {
    deleteEegSamplesData(localSessionId);
    deleteAccelerationData(localSessionId);
    return localSessionBox.remove(localSessionId);
  }

  public long deleteEegSamplesData(long localSessionId) {
    return eegSamplesQuery.setParameter(EegSample_.localSessionId, localSessionId).remove();
  }

  public long deleteAccelerationData(long localSessionId) {
    return accelerationQuery.setParameter(Acceleration_.localSessionId, localSessionId).remove();
  }
}
