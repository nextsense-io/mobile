package io.nextsense.android.base.data;

import android.os.HandlerThread;
import android.util.Log;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.atomic.AtomicBoolean;

import io.nextsense.android.base.db.objectbox.ObjectBoxDatabase;
import io.nextsense.android.base.utils.Util;
import io.objectbox.android.AndroidScheduler;
import io.objectbox.reactive.DataSubscription;

/**
 * Class in charge of monitoring the data being added in the database and uploading it to the cloud.
 * It runs in a background thread so needs to be stopped when the lifecycle owner is being shut
 * down.
 */
public class Uploader {
  private static final String TAG = Uploader.class.getSimpleName();

  private final ObjectBoxDatabase objectBoxDatabase;
  private final AtomicBoolean running = new AtomicBoolean(false);
  // Should be 1 second of data to be simple to import in BigTable.
  private final int uploadChunkSize;
  private final AtomicBoolean recordsToUpload = new AtomicBoolean(false);
  private final Object syncToken = new Object();
  private ExecutorService executor;
  private Future<?> uploadTask;
  private int recordsSinceLastNotify;
  private DataSubscription eegSampleSubscription;
  private DataSubscription activeSessionSubscription;
  private HandlerThread subscriptionsHandlerThread;
  private AndroidScheduler subscriptionsScheduler;


  private Uploader(ObjectBoxDatabase objectBoxDatabase, int uploadChunkSize) {
    this.objectBoxDatabase = objectBoxDatabase;
    this.uploadChunkSize = uploadChunkSize;
  }

  public static Uploader create(ObjectBoxDatabase objectBoxDatabase, int uploadChunkSize) {
    return new Uploader(objectBoxDatabase, uploadChunkSize);
  }

  public void start() {
    recordsSinceLastNotify = 0;
    if (running.get()) {
      Log.w(TAG, "Already running, no-op.");
      return;
    }
    subscriptionsHandlerThread = new HandlerThread("UploaderSubscriptionsHandlerThread");
    subscriptionsHandlerThread.start();
    subscriptionsScheduler = new AndroidScheduler(subscriptionsHandlerThread.getLooper());
    running.set(true);
    executor = Executors.newSingleThreadExecutor();
    uploadTask = executor.submit(this::uploadData);
  }

  public void stop() {
    Log.d(TAG, "stopping started.");
    running.set(false);
    if (eegSampleSubscription != null) {
      eegSampleSubscription.cancel();
    }
    if (activeSessionSubscription != null) {
      activeSessionSubscription.cancel();
    }
    if (subscriptionsHandlerThread != null) {
      subscriptionsHandlerThread.quit();
      subscriptionsHandlerThread = null;
    }
    synchronized (syncToken) {
      syncToken.notifyAll();
    }
    if (uploadTask != null) {
      try {
        uploadTask.get();
      } catch (ExecutionException e) {
        Log.e(TAG, "Error when stopping. " + e.getMessage());
      } catch (InterruptedException e) {
        Thread.currentThread().interrupt();
      }
    }
    if (executor != null) {
      executor.shutdown();
    }
    Log.d(TAG, "stopping finished.");
  }

  private List<EegSample> getSamplesToUpload(LocalSession localSession) {
    List<EegSample> eegSamplesToUpload = new ArrayList<>();
    if (objectBoxDatabase.getEegSamplesCount(localSession.id) -
        localSession.getEegSamplesUploaded() >= uploadChunkSize) {
      eegSamplesToUpload.addAll(objectBoxDatabase.getEegSamples(
          localSession.id, localSession.getEegSamplesUploaded(), uploadChunkSize));
    } else if (localSession.getStatus() == LocalSession.Status.FINISHED) {
      eegSamplesToUpload.addAll(objectBoxDatabase.getEegSamples(localSession.id,
          localSession.getEegSamplesUploaded(),
          objectBoxDatabase.getEegSamplesCount(localSession.id) -
              localSession.getEegSamplesUploaded()));
    }
    return eegSamplesToUpload;
  }

  private void uploadData() {
    while (running.get()) {
      List<LocalSession> localSessions = objectBoxDatabase.getLocalSessions();
      Util.logd(TAG, "There are " + localSessions.size() + " local sessions in the DB.");
      for (LocalSession localSession : localSessions) {
        if (!localSession.isUploadNeeded() ||
            (localSession.getStatus() != LocalSession.Status.RECORDING &&
            localSession.getStatus() != LocalSession.Status.FINISHED)) {
          continue;
        }
        Util.logd(TAG, "Session " + localSession.id + " has " +
            localSession.getEegSamplesUploaded() + " uploaded.");
        List<EegSample> eegSamplesToUpload = getSamplesToUpload(localSession);
        Util.logd(TAG, "Session " + localSession.id + " has " + eegSamplesToUpload.size() +
            " to upload.");
        while (!eegSamplesToUpload.isEmpty() && running.get()) {
          // TODO(eric): Run actual upload here.
          // Update the local database with the uploaded records size and mark the local session as
          // uploaded if done.
          final int eegSamplesToUploadSize = eegSamplesToUpload.size();
          objectBoxDatabase.runInTx(() -> {
            localSession.setEegSamplesUploaded(
                localSession.getEegSamplesUploaded() + eegSamplesToUploadSize);
            Util.logv(TAG, "Uploaded " + localSession.getEegSamplesUploaded() +
                " from session " + localSession.id);
            if (localSession.getStatus() == LocalSession.Status.FINISHED &&
                localSession.getEegSamplesUploaded() ==
                    objectBoxDatabase.getEegSamplesCount(localSession.id)) {
              Util.logd(TAG, "Session " + localSession.id + " upload is completed.");
              localSession.setStatus(LocalSession.Status.UPLOADED);
            }
            objectBoxDatabase.putLocalSession(localSession);
          });
          eegSamplesToUpload = getSamplesToUpload(localSession);
        }
      }
      recordsSinceLastNotify = 0;
      recordsToUpload.set(false);
      Util.logd(TAG, "All upload done, waiting for new samples.");
      // Wait until there are new samples to upload.
      eegSampleSubscription =
          objectBoxDatabase.subscribe(EegSample.class, eegSample -> {
            ++recordsSinceLastNotify;
            if (recordsSinceLastNotify >= uploadChunkSize) {
              Util.logd(TAG, "waking up: " + recordsSinceLastNotify);
              recordsSinceLastNotify = 0;
              recordsToUpload.set(true);
              synchronized (syncToken) {
                syncToken.notifyAll();
              }
            }
          }, subscriptionsScheduler);
      // If still recording, wait until the session finishes as an alternative, as it would usually
      // not reach a discrete uploadChunkSize.
      Optional<LocalSession> activeSessionOptional = objectBoxDatabase.getActiveSession();
      if (activeSessionOptional.isPresent()) {
        activeSessionSubscription = subscribeToFinishedSession(activeSessionOptional.get().id);
      }

      synchronized (syncToken) {
        while (running.get() && !recordsToUpload.get()) {
          try {
            Util.logd(TAG, "Starting to wait");
            syncToken.wait();
            Util.logd(TAG, "Wait finished");
          } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
          }
        }
      }
      eegSampleSubscription.cancel();
      if (activeSessionSubscription != null) {
        activeSessionSubscription.cancel();
      }
      Util.logd(TAG, "New records to upload, wait finished.");
    }
  }

  private DataSubscription subscribeToFinishedSession(long localSessionId) {
    return objectBoxDatabase.getFinishedLocalSession(localSessionId).subscribe()
        .on(subscriptionsScheduler).observer(finishedSessions -> {
          if (finishedSessions.isEmpty()) {
            return;
          }
          Util.logd(TAG, "Session " + finishedSessions.get(0).id + " finished, waking Uploader.");
          recordsSinceLastNotify = 0;
          recordsToUpload.set(true);
          synchronized (syncToken) {
            syncToken.notifyAll();
          }
        });
  }
}
