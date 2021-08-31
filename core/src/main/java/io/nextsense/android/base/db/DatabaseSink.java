package io.nextsense.android.base.db;

import org.greenrobot.eventbus.EventBus;
import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;

import io.nextsense.android.base.data.Acceleration;
import io.nextsense.android.base.data.EegSample;
import io.nextsense.android.base.db.objectbox.ObjectBoxDatabase;

/**
 * Listens for incoming data and saves it in the ObjectBox database.
 */
public class DatabaseSink {

  private final ObjectBoxDatabase boxDatabase;

  private DatabaseSink(ObjectBoxDatabase boxDatabase) {
    this.boxDatabase = boxDatabase;
  }

  public static DatabaseSink create(ObjectBoxDatabase objectBoxDatabase) {
    return new DatabaseSink(objectBoxDatabase);
  }

  public void startListening() {
    EventBus.getDefault().register(this);
  }

  public void stopListening() {
    EventBus.getDefault().unregister(this);
  }

  @Subscribe(threadMode = ThreadMode.BACKGROUND)
  public void onEegSample(EegSample eegSample) {
    boxDatabase.putEegSample(eegSample);
  }

  @Subscribe(threadMode = ThreadMode.BACKGROUND)
  public void onAcceleration(Acceleration acceleration) {
    boxDatabase.putAcceleration(acceleration);
  }
}
