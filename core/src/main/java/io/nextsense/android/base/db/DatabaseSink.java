package io.nextsense.android.base.db;

import org.greenrobot.eventbus.EventBus;
import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;

import java.util.concurrent.atomic.AtomicInteger;

import io.nextsense.android.base.data.DeviceInternalState;
import io.nextsense.android.base.data.EegSample;
import io.nextsense.android.base.data.LocalSessionManager;
import io.nextsense.android.base.data.Samples;
import io.nextsense.android.base.db.objectbox.ObjectBoxDatabase;
import io.nextsense.android.base.utils.RotatingFileLogger;

/**
 * Listens for incoming data and saves it in the ObjectBox database.
 */
public class DatabaseSink {

  private static final String TAG = DatabaseSink.class.getSimpleName();

  private final ObjectBoxDatabase boxDatabase;
  private final LocalSessionManager localSessionManager;
  private final AtomicInteger eegRecordsCounter = new AtomicInteger(0);
  private Samples previousSamples = null;

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
      RotatingFileLogger.get().logw(TAG, "Already registered to EventBus!");
      return;
    }
    EventBus.getDefault().register(this);
    RotatingFileLogger.get().logi(TAG, "Started listening to EventBus.");
  }

  public void stopListening() {
    EventBus.getDefault().unregister(this);
    RotatingFileLogger.get().logi(TAG, "Stopped listening to EventBus.");
  }

  public int getEegRecordsCounter() {
    return eegRecordsCounter.get();
  }

  public void resetEegRecordsCounter() {
    eegRecordsCounter.set(0);
  }

  @Subscribe(threadMode = ThreadMode.BACKGROUND)
  public void onSamples(Samples samples) {
    localSessionManager.getActiveLocalSession().ifPresent(currentLocalSession -> {
      if (!currentLocalSession.isReceivedData()) {
        localSessionManager.notifyFirstDataReceived();
      }
      if (currentLocalSession.isUploadNeeded()) {
        // Verify that the timestamps are moving forward in time.
        EegSample lastEegSample = null;
        if (previousSamples != null) {
          lastEegSample =
              previousSamples.getEegSamples().get(previousSamples.getEegSamples().size() - 1);
          if (samples.getEegSamples().get(0).localSession.getTargetId() !=
              lastEegSample.localSession.getTargetId()) {
            lastEegSample = null;
          }
        }
        int packetIndex = 0;
        for (EegSample eegSample : samples.getEegSamples()) {
          if (lastEegSample != null && eegSample.getAbsoluteSamplingTimestamp().isBefore(
                lastEegSample.getAbsoluteSamplingTimestamp())) {
            RotatingFileLogger.get().logw(TAG,
                "Received a sample that is before a previous sample, skipping packet. " +
                    "Previous timestamp: " + lastEegSample.getAbsoluteSamplingTimestamp() +
                    ", new timestamp: " + eegSample.getAbsoluteSamplingTimestamp() +
                    ", packet index: " + packetIndex);
            return;
          }
          lastEegSample = eegSample;
          packetIndex++;
        }

        // Save the samples in the local database.
        boxDatabase.runInTx(() -> {
          boxDatabase.putEegSamples(samples.getEegSamples());
          boxDatabase.putAccelerations(samples.getAccelerations());
        });
        eegRecordsCounter.getAndAdd(samples.getEegSamples().size());
        previousSamples = samples;
      }
    });
  }

  @Subscribe(threadMode = ThreadMode.BACKGROUND)
  public void onDeviceInternalState(DeviceInternalState deviceInternalState) {
    boxDatabase.putDeviceInternalState(deviceInternalState);
  }
}
