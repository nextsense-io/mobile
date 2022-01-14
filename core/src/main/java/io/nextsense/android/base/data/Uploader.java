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

  private final ObjectBoxDatabase objectBoxDatabase;
  private final FirebaseFunctions functions = FirebaseFunctions.getInstance();
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

  // TODO(eric): Should query this by sampling timestamp instead of number of records to send
  //             records based o na time period, not a record count, which might not match if there
  //             are missing samples.
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

  private @Nullable Instant getExpectedFirstEegTimestamp(
      LocalSession localSession, EegSample firstEegSampleToUpload, int frequency) {
    if (localSession.getEegSamplesUploaded() > 0) {
      return objectBoxDatabase.getEegSamples(
          localSession.id, localSession.getEegSamplesUploaded() - 1L, /*count=*/1)
          .get(0).getAbsoluteSamplingTimestamp().plusMillis(
              Math.round(Math.floor(1000f / frequency)));
    }
    return firstEegSampleToUpload.getAbsoluteSamplingTimestamp();
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
          for (int eegSamplesIndex = 0; eegSamplesIndex < eegSamplesToUpload.size();
               eegSamplesIndex += uploadChunkSize) {
            int eegSamplesEndIndex =
                Math.min(eegSamplesToUpload.size(), eegSamplesIndex + uploadChunkSize);
            DataSamplesProto.DataSamples dataSamplesProto =
                serializeToProto(eegSamplesToUpload.subList(eegSamplesIndex, eegSamplesEndIndex),
                    localSession);
            try {
              // Block on the task for a maximum of UPLOAD_FUNCTION_TIMEOUT milliseconds,
              // otherwise time out.
              Task<Map> uploadDataSamplesTask = uploadDataSamplesProto(dataSamplesProto);
              Map uploadResult = Tasks.await(
                  uploadDataSamplesTask, UPLOAD_FUNCTION_TIMEOUT.toMillis(), TimeUnit.MILLISECONDS);
              Util.logd(TAG, "Upload result: " + uploadResult.get("result"));
            } catch (IOException e) {
              Log.e(TAG, "Failed to upload data samples: " + e.getMessage(), e);
            } catch (ExecutionException e) {
              Log.e(TAG, "Failed to upload data samples: " + e.getMessage(), e);
            } catch (InterruptedException e) {
              Log.e(TAG, "Failed to upload data samples: " + e.getMessage(), e);
              Thread.currentThread().interrupt();
            } catch (TimeoutException e) {
              Log.e(TAG, "Failed to upload data samples: " + e.getMessage(), e);
            }
          }

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

  private DataSamplesProto.DataSamples serializeToProto(List<EegSample> eegSamplesToUpload,
                                                        LocalSession localSession) {
    DataSamplesProto.DataSamples.Builder dataSamplesProtoBuilder =
        DataSamplesProto.DataSamples.newBuilder();
    if (localSession.getUserBigTableKey() != null) {
      dataSamplesProtoBuilder.setUserId(localSession.getUserBigTableKey());
    }
    if (localSession.getCloudDataSessionId() != null) {
      dataSamplesProtoBuilder.setDataSessionId(localSession.getCloudDataSessionId());
    }
    dataSamplesProtoBuilder.setModality(DataSamplesProto.DataSamples.Modality.EAR_EEG);
    dataSamplesProtoBuilder.setFrequency(uploadChunkSize);
    dataSamplesProtoBuilder.setExpectedSamplesCount(eegSamplesToUpload.size());
    Instant expectedStartInstant =
        getExpectedFirstEegTimestamp(localSession, eegSamplesToUpload.get(0), uploadChunkSize);
    Timestamp expectedStartTimestamp = Timestamp.newBuilder()
        .setSeconds(expectedStartInstant.getEpochSecond())
        .setNanos(expectedStartInstant.getNano()).build();
    dataSamplesProtoBuilder.setExpectedStartTimestamp(expectedStartTimestamp);
    Map<Integer, DataSamplesProto.Channel.Builder> channelBuilders = new HashMap<>();
    for (EegSample eegSample : eegSamplesToUpload) {
      Timestamp samplingTimestamp = Timestamp.newBuilder()
          .setSeconds(eegSample.getAbsoluteSamplingTimestamp().getEpochSecond())
          .setNanos(eegSample.getAbsoluteSamplingTimestamp().getNano()).build();
      dataSamplesProtoBuilder.addSamplingTimestamp(samplingTimestamp);
      for (Integer channel : eegSample.getEegSamples().keySet()) {
        DataSamplesProto.Channel.Builder channelBuilder = channelBuilders.computeIfAbsent(
            channel, channelValue ->
                DataSamplesProto.Channel.newBuilder().setNumber(channelValue));
        channelBuilder.addSample(eegSample.getEegSamples().get(channel));
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

  private Task<Map> uploadDataSamplesProto(DataSamplesProto.DataSamples dataSamplesProto)
      throws IOException {
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
        .continueWith(new Continuation<HttpsCallableResult, Map>() {
          @Override
          public Map then(@NonNull Task<HttpsCallableResult> task) throws Exception {
            // This continuation runs on either success or failure, but if the task
            // has failed then getResult() will throw an Exception which will be
            // propagated down.
            Map result = (Map) task.getResult().getData();
            Util.logd(TAG, "Upload data sample result: " + result);
            return result;
          }
        });
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
