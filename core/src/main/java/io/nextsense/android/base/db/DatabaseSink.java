package io.nextsense.android.base.db;

import android.util.Log;

import org.greenrobot.eventbus.EventBus;
import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;

import io.nextsense.android.base.data.DeviceInternalState;
import io.nextsense.android.base.data.Sample;
import io.nextsense.android.base.db.objectbox.ObjectBoxDatabase;

/**
 * Listens for incoming data and saves it in the ObjectBox database.
 */
public class DatabaseSink {

  private static final String TAG = DatabaseSink.class.getSimpleName();

  private final ObjectBoxDatabase boxDatabase;

  private DatabaseSink(ObjectBoxDatabase boxDatabase) {
    this.boxDatabase = boxDatabase;
  }

  public static DatabaseSink create(ObjectBoxDatabase objectBoxDatabase) {
    return new DatabaseSink(objectBoxDatabase);
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
  public void onSample(Sample sample) {
    boxDatabase.runInTx(() -> {
      boxDatabase.putEegSample(sample.getEegSample());
      boxDatabase.putAcceleration(sample.getAcceleration());
    });

  }

  @Subscribe(threadMode = ThreadMode.BACKGROUND)
  public void onDeviceInternalState(DeviceInternalState deviceInternalState) {
    boxDatabase.putDeviceInternalState(deviceInternalState);
  }
}
