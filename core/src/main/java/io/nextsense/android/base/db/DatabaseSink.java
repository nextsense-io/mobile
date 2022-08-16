package io.nextsense.android.base.db;

import android.util.Log;

import org.greenrobot.eventbus.EventBus;
import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;

import java.time.Instant;

import io.nextsense.android.base.data.DeviceInternalState;
import io.nextsense.android.base.data.LocalSessionManager;
import io.nextsense.android.base.data.Samples;
import io.nextsense.android.base.db.objectbox.ObjectBoxDatabase;

/**
 * Listens for incoming data and saves it in the ObjectBox database.
 */
public class DatabaseSink {

  private static final String TAG = DatabaseSink.class.getSimpleName();

  private final ObjectBoxDatabase boxDatabase;
  private final LocalSessionManager localSessionManager;

  private DatabaseSink(ObjectBoxDatabase boxDatabase, LocalSessionManager localSessionManager) {
    this.boxDatabase = boxDatabase;
    this.localSessionManager = localSessionManager;
  }

  public static DatabaseSink create(
      ObjectBoxDatabase objectBoxDatabase, LocalSessionManager localSessionManager) {
    return new DatabaseSink(objectBoxDatabase, localSessionManager);
  }

  public void startListening() {
    if (EventBus.getDefault().isRegistered(this)) {
      Log.w(TAG, "Already registered to EventBus!");
      return;
    }
    EventBus.getDefault().register(this);
    Log.i(TAG, "Started listening to EventBus.");
  }

  public void stopListening() {
    EventBus.getDefault().unregister(this);
    Log.i(TAG, "Stopped listening to EventBus.");
  }

  @Subscribe(threadMode = ThreadMode.BACKGROUND)
  public void onSamples(Samples samples) {
    localSessionManager.getActiveLocalSession().ifPresent((currentLocalSession) -> {
      if (currentLocalSession.isUploadNeeded()) {
        Instant saveStartTime = Instant.now();
        boxDatabase.runInTx(() -> {
          boxDatabase.putEegSamples(samples.getEegSamples());
          boxDatabase.putAccelerations(samples.getAccelerations());
        });
        long saveTime = Instant.now().toEpochMilli() - saveStartTime.toEpochMilli();
        if (saveTime > 20) {
          Log.d(TAG, "It took " + saveTime + " to write xenon data.");
        }
      }
    });
  }

  @Subscribe(threadMode = ThreadMode.BACKGROUND)
  public void onDeviceInternalState(DeviceInternalState deviceInternalState) {
    boxDatabase.putDeviceInternalState(deviceInternalState);
  }
}
