package io.nextsense.android.base.db;

import org.greenrobot.eventbus.EventBus;
import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;

import java.util.concurrent.atomic.AtomicInteger;

import io.nextsense.android.base.communication.internet.Connectivity;
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
  private final Connectivity connectivity;
  private final AtomicInteger eegRecordsCounter = new AtomicInteger(0);
  private Samples previousSamples = null;
  private int lastEegFrequency = 0;

  private DatabaseSink(ObjectBoxDatabase boxDatabase, LocalSessionManager localSessionManager,
                       Connectivity connectivity) {
    this.boxDatabase = boxDatabase;
    this.localSessionManager = localSessionManager;
    this.connectivity = connectivity;
  }

  public static DatabaseSink create(
      ObjectBoxDatabase objectBoxDatabase, LocalSessionManager localSessionManager,
      Connectivity connectivity) {
    return new DatabaseSink(objectBoxDatabase, localSessionManager, connectivity);
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

  public int getLastSessionEegFrequency() {
    return lastEegFrequency;
  }

  public void resetEegRecordsCounter() {
    eegRecordsCounter.set(0);
  }

  @Subscribe(threadMode = ThreadMode.BACKGROUND)
  public synchronized void onSamples(Samples samples) {
    if (localSessionManager.getActiveLocalSession().isEmpty()) {
      RotatingFileLogger.get().logw(TAG, "Received samples but no active session.");
      return;
    }
    localSessionManager.getActiveLocalSession().ifPresent(currentLocalSession -> {
      if (!currentLocalSession.isReceivedData()) {
        localSessionManager.notifyFirstDataReceived(samples.getEegSamples().get(0));
      }
      if (currentLocalSession.isUploadNeeded() &&
          connectivity.getState() == Connectivity.State.FULL_CONNECTION) {
        // Verify that the timestamps are moving forward in time.
        EegSample lastEegSample = null;
        if (previousSamples != null && !previousSamples.getEegSamples().isEmpty() &&
            !samples.getEegSamples().isEmpty()) {
          lastEegSample =
              previousSamples.getEegSamples().get(previousSamples.getEegSamples().size() - 1);
          if (samples.getEegSamples().get(0).localSession.getTargetId() !=
              lastEegSample.localSession.getTargetId()) {
            lastEegSample = null;
          }
        }
        int packetIndex = 0;
        for (EegSample eegSample : samples.getEegSamples()) {
          if (lastEegSample != null && lastEegSample.getAbsoluteSamplingTimestamp() != null &&
              eegSample.getAbsoluteSamplingTimestamp().isBefore(
                lastEegSample.getAbsoluteSamplingTimestamp())) {
            RotatingFileLogger.get().logw(TAG,
                "Received a sample that is before a previous sample, skipping packet. " +
                    "Previous timestamp: " + lastEegSample.getAbsoluteSamplingTimestamp() +
                    ", new timestamp: " + eegSample.getAbsoluteSamplingTimestamp() +
                    ", packet index: " + packetIndex);
            return;
          }
//          if (lastEegSample != null && lastEegSample.getRelativeSamplingTimestamp() != null &&
//              eegSample.getRelativeSamplingTimestamp() != null &&
//              eegSample.getRelativeSamplingTimestamp() <=
//                  lastEegSample.getRelativeSamplingTimestamp()) {
//            RotatingFileLogger.get().logw(TAG,
//                "Received a sample that is before a previous sample, skipping packet. " +
//                    "Previous timestamp: " + lastEegSample.getRelativeSamplingTimestamp() +
//                    ", new timestamp: " + eegSample.getRelativeSamplingTimestamp() +
//                    ", packet index: " + packetIndex);
//            return;
//          }
          lastEegSample = eegSample;
          packetIndex++;
        }

        lastEegFrequency = (int)localSessionManager.getActiveLocalSession().get().getEegSampleRate();
        // Save the samples in the local database.
        if ((!samples.getEegSamples().isEmpty() && samples.getEegSamples().size() != 50) ||
            (!samples.getAccelerations().isEmpty() && samples.getAccelerations().size() != 5) ||
            (!samples.getAngularSpeeds().isEmpty() && samples.getAngularSpeeds().size() != 5)) {
          RotatingFileLogger.get().logw(TAG,
              "Received a packet with an unexpected number of samples: " +
                  samples.getEegSamples().size() + " eeg samples, " +
                  samples.getAccelerations().size() + " accelerations, " +
                  samples.getAngularSpeeds().size() + " angular speeds.");
        }
        boxDatabase.runInTx(() -> {
          boxDatabase.putEegSamples(samples.getEegSamples());
          boxDatabase.putAccelerations(samples.getAccelerations());
          boxDatabase.putAngularSpeeds(samples.getAngularSpeeds());
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
