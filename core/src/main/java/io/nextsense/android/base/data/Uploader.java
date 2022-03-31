package io.nextsense.android.base.data;

import android.os.HandlerThread;
import android.util.Base64;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.google.android.gms.tasks.Continuation;
import com.google.android.gms.tasks.Task;
import com.google.android.gms.tasks.Tasks;
import com.google.firebase.functions.FirebaseFunctions;
import com.google.firebase.functions.HttpsCallableResult;
import com.google.protobuf.Timestamp;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.concurrent.atomic.AtomicBoolean;

import io.nextsense.android.base.DataSamplesProto;
import io.nextsense.android.base.communication.internet.Connectivity;
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
  private static final Duration UPLOAD_FUNCTION_TIMEOUT = Duration.ofMillis(10000);
  private static final String EEG_SAMPLES = "eeg_samples";
  private static final String ACC_SAMPLES = "acc_samples";

  private final ObjectBoxDatabase objectBoxDatabase;
  private final Connectivity connectivity;
  private final FirebaseFunctions functions = FirebaseFunctions.getInstance();
  private final AtomicBoolean running = new AtomicBoolean(false);
  // Should be 1 second of data to be simple to import in BigTable.
  private final int uploadChunkSize;
  // How many recent records to keep in a session locally after upload.
  private final int minRecordsToKeep;
  // Minimum retention time for records, used to match timestamps in database.
  private final Duration minDurationToKeep;
  private final AtomicBoolean recordsToUpload = new AtomicBoolean(false);
  private final Object syncToken = new Object();
  private ExecutorService executor;
  private Future<?> uploadTask;
  private int recordsSinceLastNotify;
  private DataSubscription eegSampleSubscription;
  private DataSubscription activeSessionSubscription;
  private HandlerThread subscriptionsHandlerThread;
  private AndroidScheduler subscriptionsScheduler;
  private boolean started;
  private Connectivity.State minimumConnectivityState = Connectivity.State.FULL_CONNECTION;
  private Connectivity.State currentConnectivityState = Connectivity.State.NO_CONNECTION;

  private Uploader(ObjectBoxDatabase objectBoxDatabase, Connectivity connectivity,
                   int uploadChunkSize, int minRecordsToKeep, Duration minDurationToKeep) {
    this.objectBoxDatabase = objectBoxDatabase;
    this.connectivity = connectivity;
    this.uploadChunkSize = uploadChunkSize;
    this.minRecordsToKeep = minRecordsToKeep;
    this.minDurationToKeep = minDurationToKeep;
  }

  public static Uploader create(ObjectBoxDatabase objectBoxDatabase, Connectivity connectivity,
                                int uploadChunkSize, int minRecordsToKeep,
                                Duration minDurationToKeep) {
    return new Uploader(objectBoxDatabase, connectivity, uploadChunkSize, minRecordsToKeep,
        minDurationToKeep);
  }

  public void start() {
    if (started) {
      Log.w(TAG, "Already started, no-op.");
      return;
    }
    connectivity.addStateListener(connectivityStateListener);
    started = true;
    Log.i(TAG, "Started.");
  }

  public void stop() {
    connectivity.removeStateListener(connectivityStateListener);
    stopRunning();
    started = false;
    Log.i(TAG, "Stopped.");
  }

  public void setMinimumConnectivityState(Connectivity.State connectivityState) {
    minimumConnectivityState = connectivityState;
    Log.i(TAG, "Minimum connectivity set to " + minimumConnectivityState.name());
    onConnectivityStateChanged();
  }

  private void startRunning() {
    if (running.get()) {
      Log.w(TAG, "Already running, no-op.");
      return;
    }
    Log.i(TAG, "Starting to run.");
    recordsSinceLastNotify = 0;
    subscriptionsHandlerThread = new HandlerThread("UploaderSubscriptionsHandlerThread");
    subscriptionsHandlerThread.start();
    subscriptionsScheduler = new AndroidScheduler(subscriptionsHandlerThread.getLooper());
    running.set(true);
    executor = Executors.newSingleThreadExecutor();
    uploadTask = executor.submit(this::uploadData);
    Log.i(TAG, "Started running.");
  }

  private void stopRunning() {
    if (!running.get()) {
      Log.w(TAG, "Already stopped, no-op.");
      return;
    }
    Log.i(TAG, "Stopping to run.");
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
    Log.i(TAG, "Stopped running.");
  }

  // TODO(eric): Should query this by sampling timestamp instead of number of records to send
  //             records based on a time period, not a record count, which might not match if there
  //             are missing samples.
  private Map<String, List<BaseRecord>> getSamplesToUpload(LocalSession localSession) {
    Map<String, List<BaseRecord>> samplesToUpload = new HashMap<>();
    List<BaseRecord> eegSamplesToUpload = new ArrayList<>();
    long relativeEegStartOffset = localSession.getEegSamplesUploaded() -
        localSession.getEegSamplesDeleted();
    long sessionEegSamplesCount = objectBoxDatabase.getEegSamplesCount(localSession.id) +
        localSession.getEegSamplesDeleted();
    if (sessionEegSamplesCount - localSession.getEegSamplesUploaded() >= uploadChunkSize) {
      eegSamplesToUpload.addAll(objectBoxDatabase.getEegSamples(
          localSession.id, relativeEegStartOffset, uploadChunkSize));
    } else if (objectBoxDatabase.getLocalSession(localSession.id).getStatus() ==
        LocalSession.Status.FINISHED) {
      eegSamplesToUpload.addAll(objectBoxDatabase.getEegSamples(localSession.id,
          relativeEegStartOffset,
          sessionEegSamplesCount - localSession.getEegSamplesUploaded()));
    }
    samplesToUpload.put(EEG_SAMPLES, eegSamplesToUpload);

    List<BaseRecord> accelerationsToUpload = new ArrayList<>();
    long relativeAccStartOffset = localSession.getAccelerationsUploaded() -
        localSession.getEegSamplesDeleted();
    long sessionAccSamplesCount = objectBoxDatabase.getAccelerationCount(localSession.id) +
        localSession.getAccelerationsDeleted();
    if (sessionAccSamplesCount - localSession.getAccelerationsUploaded() >= uploadChunkSize) {
      accelerationsToUpload.addAll(objectBoxDatabase.getAccelerations(
          localSession.id, relativeAccStartOffset, uploadChunkSize));
    } else if (objectBoxDatabase.getLocalSession(localSession.id).getStatus() ==
        LocalSession.Status.FINISHED) {
      accelerationsToUpload.addAll(objectBoxDatabase.getAccelerations(localSession.id,
          relativeAccStartOffset,
          sessionAccSamplesCount - localSession.getAccelerationsUploaded()));
    }
    samplesToUpload.put(ACC_SAMPLES, accelerationsToUpload);

    return samplesToUpload;
  }

  private @Nullable Instant getExpectedFirstEegTimestamp(
      LocalSession localSession, EegSample firstEegSampleToUpload, int frequency) {
    if (localSession.getEegSamplesUploaded() > 0) {
      return objectBoxDatabase.getEegSamples(
          localSession.id, localSession.getEegSamplesUploaded() -
              localSession.getEegSamplesDeleted() - 1L, /*count=*/1)
              .get(0).getAbsoluteSamplingTimestamp().plusMillis(
              Math.round(Math.floor(1000f / frequency)));
    }
    return firstEegSampleToUpload.getAbsoluteSamplingTimestamp();
  }

  private boolean dataToUpload(Map<String, List<BaseRecord>> dataSamplesMap) {
    return (dataSamplesMap.get(EEG_SAMPLES) != null && !dataSamplesMap.get(EEG_SAMPLES).isEmpty())
        || (dataSamplesMap.get(ACC_SAMPLES) != null && !dataSamplesMap.get(ACC_SAMPLES).isEmpty());
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
        Map<String, List<BaseRecord>> samplesToUpload = getSamplesToUpload(localSession);
        List<BaseRecord> eegSamplesToUpload = samplesToUpload.get(EEG_SAMPLES);
        Util.logd(TAG, "Session " + localSession.id + " has " + eegSamplesToUpload.size() +
            " eeg records to upload.");
        while (dataToUpload(samplesToUpload) && running.get()) {
          boolean uploaded = false;
          for (int eegSamplesIndex = 0; eegSamplesIndex < eegSamplesToUpload.size();
               eegSamplesIndex += uploadChunkSize) {
            int eegSamplesEndIndex =
                Math.min(eegSamplesToUpload.size(), eegSamplesIndex + uploadChunkSize);
            Map<String, List<BaseRecord>> samplesChunkToUpload = new HashMap<>();
            samplesChunkToUpload.put(EEG_SAMPLES,
                eegSamplesToUpload.subList(eegSamplesIndex, eegSamplesEndIndex));
            samplesChunkToUpload.put(ACC_SAMPLES,
                samplesToUpload.get(ACC_SAMPLES).subList(eegSamplesIndex, eegSamplesEndIndex));
            DataSamplesProto.DataSamples dataSamplesProto =
                serializeToProto(samplesChunkToUpload, localSession);
            try {
              // Block on the task for a maximum of UPLOAD_FUNCTION_TIMEOUT milliseconds,
              // otherwise time out.
              Task<Map<String, Object>> uploadDataSamplesTask =
                  uploadDataSamplesProto(dataSamplesProto);
              Map<String, Object> uploadResult = Tasks.await(
                  uploadDataSamplesTask, UPLOAD_FUNCTION_TIMEOUT.toMillis(), TimeUnit.MILLISECONDS);
              uploaded = true;
              Util.logd(TAG, "Upload result: " + uploadResult.get("result"));
            } catch (IOException | ExecutionException | TimeoutException e) {
              Log.e(TAG, "Failed to upload data samples: " + e.getMessage(), e);
            } catch (InterruptedException e) {
              Log.e(TAG, "Failed to upload data samples: " + e.getMessage(), e);
              Thread.currentThread().interrupt();
            }
          }

          // Update the local database with the uploaded records size and mark the local session as
          // uploaded if done.
          if (uploaded) {
            final int eegSamplesToUploadSize = eegSamplesToUpload.size();
            final int accelerationsToUploadSize = samplesToUpload.get(ACC_SAMPLES).size();
            objectBoxDatabase.runInTx(() -> {
              localSession.setEegSamplesUploaded(
                  localSession.getEegSamplesUploaded() + eegSamplesToUploadSize);
              localSession.setAccelerationsUploaded(
                  localSession.getAccelerationsUploaded() + accelerationsToUploadSize);
              Util.logv(TAG, "Uploaded " + localSession.getEegSamplesUploaded() +
                  " eeg samples from session " + localSession.id);
              // Need to check the status from the DB as it could get updated to finished in another
              // thread.
              localSession.setStatus(objectBoxDatabase.getLocalSession(localSession.id).getStatus());
              if (localSession.getStatus() ==
                  LocalSession.Status.FINISHED && localSession.getEegSamplesUploaded() ==
                      objectBoxDatabase.getEegSamplesCount(localSession.id) +
                          localSession.getEegSamplesDeleted() &&
                  localSession.getAccelerationsUploaded() ==
                  objectBoxDatabase.getAccelerationCount(localSession.id) +
                      localSession.getAccelerationsDeleted()) {
                Util.logd(TAG, "Session " + localSession.id + " upload is completed.");
                localSession.setStatus(LocalSession.Status.UPLOADED);
                // This could be deleted at a later time in case the data needs to be analyzed or
                // displayed in the app.
                objectBoxDatabase.deleteLocalSession(localSession.id);
              }
              objectBoxDatabase.putLocalSession(localSession);
            });
            if (localSession.getStatus() != LocalSession.Status.UPLOADED) {
              objectBoxDatabase.runInTx(() -> {
                long eegRecordsDeleted = deleteEegOldRecords(localSession);
                long accelerationRecordsDeleted = deleteAccelerationOldRecords(localSession);
                Util.logd(TAG, "Deleted " + eegRecordsDeleted + " eeg records.");
                if (eegRecordsDeleted > 0 || accelerationRecordsDeleted > 0) {
                  localSession.setEegSamplesDeleted(
                      localSession.getEegSamplesDeleted() + eegRecordsDeleted);
                  localSession.setAccelerationsDeleted(
                      localSession.getAccelerationsDeleted() + accelerationRecordsDeleted);
                  objectBoxDatabase.putLocalSession(localSession);
                }
              });
            }
          }
          // TODO(eric): Implement more error mitigation strategies:
          //             - backoff retry.
          //             - notifications to user/NextSense.
          // If it did not work, it will try to upload again.
          samplesToUpload = getSamplesToUpload(localSession);
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

  DateTimeFormatter formatter =
      DateTimeFormatter.ISO_LOCAL_DATE_TIME.withZone(ZoneId.from(ZoneOffset.UTC));

  private long deleteEegOldRecords(LocalSession localSession) {
    if (objectBoxDatabase.getEegSamplesCount(localSession.id) > minRecordsToKeep) {
      Util.logd(TAG, "Got " + objectBoxDatabase.getEegSamplesCount(localSession.id) +
          " eeg records in db, need to delete " +
          (objectBoxDatabase.getEegSamplesCount(localSession.id) - minRecordsToKeep));
      Instant lastSampleTime = objectBoxDatabase.getEegSamples(
          localSession.id, localSession.getEegSamplesUploaded() -
              localSession.getEegSamplesDeleted() - 1L, /*count=*/1)
          .get(0).getAbsoluteSamplingTimestamp();
      Instant cutOffDate = lastSampleTime.minus(minDurationToKeep);
      Util.logd(TAG, "EEG Cutoff time: " + formatter.format(cutOffDate));
      return objectBoxDatabase.deleteFirstEegSamplesData(localSession.id,
          cutOffDate.toEpochMilli());
    }
    return 0;
  }

  private long deleteAccelerationOldRecords(LocalSession localSession) {
    if (objectBoxDatabase.getAccelerationCount(localSession.id) > minRecordsToKeep) {
      Util.logd(TAG, "Got " + objectBoxDatabase.getAccelerationCount(localSession.id) +
          " acceleration records in db, need to delete " +
          (objectBoxDatabase.getAccelerationCount(localSession.id) - minRecordsToKeep));
      Instant lastSampleTime = objectBoxDatabase.getAccelerations(
          localSession.id, localSession.getAccelerationsUploaded() -
              localSession.getAccelerationsDeleted() - 1L, /*count=*/1)
          .get(0).getAbsoluteSamplingTimestamp();
      Instant cutOffDate = lastSampleTime.minus(minDurationToKeep);
      Util.logd(TAG, "Accelration cutoff time: " + formatter.format(cutOffDate));
      return objectBoxDatabase.deleteFirstAccelerationsData(localSession.id,
          cutOffDate.toEpochMilli());
    }
    return 0;
  }

  private DataSamplesProto.DataSamples serializeToProto(Map<String, List<BaseRecord>> samples,
                                                        LocalSession localSession) {
    // TODO(eric): If acceleration is not on the same frequency as eeg, should send it in a separate
    //             proto?
    List<BaseRecord> eegSamplesToUpload = samples.get(EEG_SAMPLES);
    List<BaseRecord> accelerationsToUpload = samples.get(ACC_SAMPLES);
    assert(eegSamplesToUpload != null);
    assert(accelerationsToUpload != null);
    assert(eegSamplesToUpload.size() == accelerationsToUpload.size());
    DataSamplesProto.DataSamples.Builder dataSamplesProtoBuilder =
        DataSamplesProto.DataSamples.newBuilder();
    if (localSession.getUserBigTableKey() != null) {
      dataSamplesProtoBuilder.setUserId(localSession.getUserBigTableKey());
    }
    if (localSession.getCloudDataSessionId() != null) {
      dataSamplesProtoBuilder.setDataSessionId(localSession.getCloudDataSessionId());
    }
    dataSamplesProtoBuilder.setModality(DataSamplesProto.DataSamples.Modality.EAR_EEG);
    if (localSession.getEarbudsConfig() != null) {
      dataSamplesProtoBuilder.setEarbudsConfig(localSession.getEarbudsConfig());
    }
    dataSamplesProtoBuilder.setFrequency(uploadChunkSize);
    dataSamplesProtoBuilder.setExpectedSamplesCount(eegSamplesToUpload.size());
    Instant expectedStartInstant = getExpectedFirstEegTimestamp(
        localSession, (EegSample) eegSamplesToUpload.get(0), uploadChunkSize);
    Timestamp expectedStartTimestamp = Timestamp.newBuilder()
        .setSeconds(expectedStartInstant.getEpochSecond())
        .setNanos(expectedStartInstant.getNano()).build();
    dataSamplesProtoBuilder.setExpectedStartTimestamp(expectedStartTimestamp);
    Map<String, DataSamplesProto.Channel.Builder> channelBuilders = new HashMap<>();
    for (int i = 0; i < eegSamplesToUpload.size(); ++i) {
      EegSample eegSample = (EegSample) eegSamplesToUpload.get(i);
      Timestamp samplingTimestamp = Timestamp.newBuilder()
          .setSeconds(eegSample.getAbsoluteSamplingTimestamp().getEpochSecond())
          .setNanos(eegSample.getAbsoluteSamplingTimestamp().getNano()).build();
      dataSamplesProtoBuilder.addSamplingTimestamp(samplingTimestamp);
      for (Integer channel : eegSample.getEegSamples().keySet()) {
        DataSamplesProto.Channel.Builder channelBuilder = channelBuilders.computeIfAbsent(
            String.valueOf(channel), channelValue ->
                DataSamplesProto.Channel.newBuilder().setNumber(String.valueOf(channel)));
        channelBuilder.addSample(eegSample.getEegSamples().get(channel));
      }
      Acceleration acceleration = (Acceleration) accelerationsToUpload.get(i);
      for (String accChannel : Acceleration.CHANNELS) {
        DataSamplesProto.Channel.Builder channelBuilder = channelBuilders.computeIfAbsent(
            accChannel, channelValue -> DataSamplesProto.Channel.newBuilder().setNumber(accChannel));
        switch (Acceleration.Channels.valueOf(accChannel.toUpperCase())) {
          case X:
            channelBuilder.addSample(acceleration.getX());
            break;
          case Y:
            channelBuilder.addSample(acceleration.getY());
            break;
          case Z:
            channelBuilder.addSample(acceleration.getZ());
            break;
        }
      }
      dataSamplesProtoBuilder.addSync(eegSample.getSync());
      dataSamplesProtoBuilder.addTrigOut(eegSample.getTrigOut());
      dataSamplesProtoBuilder.addTrigIn(eegSample.getTrigIn());
      dataSamplesProtoBuilder.addZMod(eegSample.getZMod());
      dataSamplesProtoBuilder.addMarker(eegSample.getMarker());
      dataSamplesProtoBuilder.addButton(eegSample.getButton());
    }
    for (DataSamplesProto.Channel.Builder channelBuilder : channelBuilders.values()) {
      dataSamplesProtoBuilder.addChannel(channelBuilder.build());
    }
    return dataSamplesProtoBuilder.build();
  }

  private Task<Map<String, Object>> uploadDataSamplesProto(
      DataSamplesProto.DataSamples dataSamplesProto) throws IOException {
    // Create the arguments to the callable function.
    Log.i(TAG, "Starting upload with callable function.");
    Map<String, Object> data = new HashMap<>();
    ByteArrayOutputStream byteArrayOutputStream =
        new ByteArrayOutputStream(dataSamplesProto.getSerializedSize());
    dataSamplesProto.writeTo(byteArrayOutputStream);
    data.put("data_samples_proto",
        Base64.encodeToString(byteArrayOutputStream.toByteArray(), Base64.DEFAULT));

    return functions
        .getHttpsCallable("upload_data_samples")
        .call(data)
        .addOnFailureListener(exception ->
            Log.e(TAG, "Failed to upload data: " + exception.getMessage()))
        .continueWith(new Continuation<>() {
          @Override
          public Map<String, Object> then(@NonNull Task<HttpsCallableResult> task)
              throws Exception {
            // This continuation runs on either success or failure, but if the task
            // has failed then getResult() will throw an Exception which will be
            // propagated down.
            if (task.getResult() != null) {
              @SuppressWarnings("unchecked")
              Map<String, Object> result = (Map<String, Object>) task.getResult().getData();
              Util.logd(TAG, "Upload data sample result: " + result);
              return result;
            }
            return new HashMap<>();
          }
        });
  }

  private DataSubscription subscribeToFinishedSession(long localSessionId) {
    return objectBoxDatabase.getFinishedLocalSession(localSessionId).subscribe()
        .on(subscriptionsScheduler).observer(finishedSessions -> {
          if (finishedSessions.isEmpty()) {
            return;
          }
          Util.logd(TAG, "Session " + finishedSessions.get(0).id +
              " finished, waking Uploader.");
          recordsSinceLastNotify = 0;
          recordsToUpload.set(true);
          synchronized (syncToken) {
            syncToken.notifyAll();
          }
        });
  }

  private void onConnectivityStateChanged() {
    if (currentConnectivityState == Connectivity.State.FULL_CONNECTION ||
        currentConnectivityState == minimumConnectivityState) {
      startRunning();
    } else {
      stopRunning();
    }
  }

  private final Connectivity.StateListener connectivityStateListener = newState -> {
    currentConnectivityState = newState;
    onConnectivityStateChanged();
  };
}
