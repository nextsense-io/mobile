package io.nextsense.android.base.data;

import android.content.ContentValues;
import android.content.Context;
import android.net.Uri;
import android.os.HandlerThread;
import android.provider.MediaStore;
import android.util.Log;

import androidx.annotation.Nullable;

import com.google.protobuf.Timestamp;

import java.io.ByteArrayOutputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.OutputStream;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.atomic.AtomicBoolean;

import io.nextsense.android.ApplicationType;
import io.nextsense.android.base.DataSamplesProto;
import io.nextsense.android.base.SessionProto;
import io.nextsense.android.base.communication.firebase.CloudFunctions;
import io.nextsense.android.base.communication.internet.Connectivity;
import io.nextsense.android.base.db.DatabaseSink;
import io.nextsense.android.base.db.objectbox.ObjectBoxDatabase;
import io.nextsense.android.base.utils.RotatingFileLogger;
import io.objectbox.android.AndroidScheduler;
import io.objectbox.reactive.DataSubscription;

/**
 * Class in charge of monitoring the data being added in the database and uploading it to the cloud.
 * It runs in a background thread so needs to be stopped when the lifecycle owner is being shut
 * down.
 */
public class Uploader {
  private static final String TAG = Uploader.class.getSimpleName();
  private static final String EEG_SAMPLES = "eeg_samples";
  private static final String ACC_SAMPLES = "acc_samples";
  private static final String INT_STATE_SAMPLES = "device_internal_state_samples";

  // Should be 1 second of data to be simple to import in BigTable.
  private final Duration uploadChunkSize;
  private final Context context;
  private final ApplicationType applicationType;
  private final ObjectBoxDatabase objectBoxDatabase;
  private final DatabaseSink databaseSink;
  private final CloudFunctions firebaseFunctions;
  private final Connectivity connectivity;
  private final AtomicBoolean running = new AtomicBoolean(false);
  // How many recent records to keep in a session locally after upload.
  private final int minRecordsToKeep;
  // Minimum retention time for records, used to match timestamps in database.
  private final Duration minDurationToKeep;
  private final AtomicBoolean recordsToUpload = new AtomicBoolean(false);
  private final Object syncToken = new Object();
  private ExecutorService executor;
  private Future<?> uploadTask;
  private DataSubscription eegSampleSubscription;
  private DataSubscription activeSessionSubscription;
  private HandlerThread subscriptionsHandlerThread;
  private AndroidScheduler subscriptionsScheduler;
  // Once the session is marked as finished, run a timer to see when all data is transferred. Once
  // that is done, can upload the remaining data that is less than the chunk size.
  private Timer waitForDataTimer;
  private boolean started = false;
  private Connectivity.State minimumConnectivityState = Connectivity.State.FULL_CONNECTION;
  private Connectivity.State currentConnectivityState = Connectivity.State.NO_CONNECTION;
  // Used to generate test data manually, should always be false in production.
  private boolean saveTestProtoData = false;

  private Uploader(Context context, ApplicationType applicationType,
                   ObjectBoxDatabase objectBoxDatabase, DatabaseSink databaseSink,
                   Connectivity connectivity, Duration uploadChunkSize, int minRecordsToKeep,
                   Duration minDurationToKeep) {
    this.context = context;
    this.objectBoxDatabase = objectBoxDatabase;
    this.databaseSink = databaseSink;
    this.connectivity = connectivity;
    this.uploadChunkSize = uploadChunkSize;
    this.minRecordsToKeep = minRecordsToKeep;
    this.minDurationToKeep = minDurationToKeep;
    this.firebaseFunctions = CloudFunctions.create();
    this.applicationType = applicationType;
  }

  public static Uploader create(
      Context context, ApplicationType applicationType, ObjectBoxDatabase objectBoxDatabase,
      DatabaseSink databaseSink, Connectivity connectivity, Duration uploadChunkSize,
      int minRecordsToKeep, Duration minDurationToKeep) {
    return new Uploader(context, applicationType, objectBoxDatabase, databaseSink, connectivity,
        uploadChunkSize, minRecordsToKeep, minDurationToKeep);
  }

  public void start() {
    if (started) {
      RotatingFileLogger.get().logw(TAG, "Already started, no-op.");
      return;
    }
    connectivity.addStateListener(connectivityStateListener);
    started = true;
    RotatingFileLogger.get().logi(TAG, "Started.");
  }

  public void stop() {
    connectivity.removeStateListener(connectivityStateListener);
    stopRunning();
    started = false;
    RotatingFileLogger.get().logi(TAG, "Stopped.");
  }

  public void setMinimumConnectivityState(Connectivity.State connectivityState) {
    minimumConnectivityState = connectivityState;
    RotatingFileLogger.get().logi(TAG, "Minimum connectivity set to " + minimumConnectivityState.name());
    onConnectivityStateChanged();
  }

  private void startRunning() {
    if (running.get()) {
      RotatingFileLogger.get().logw(TAG, "Already running, no-op.");
      return;
    }
    RotatingFileLogger.get().logi(TAG, "Starting to run.");
    cleanActiveSessions();
    databaseSink.resetEegRecordsCounter();
    subscriptionsHandlerThread = new HandlerThread("UploaderSubscriptionsHandlerThread");
    subscriptionsHandlerThread.start();
    subscriptionsScheduler = new AndroidScheduler(subscriptionsHandlerThread.getLooper());
    running.set(true);
    executor = Executors.newSingleThreadExecutor();
    uploadTask = executor.submit(this::uploadData);
    RotatingFileLogger.get().logi(TAG, "Started running.");
  }

  private void stopRunning() {
    if (!running.get()) {
      RotatingFileLogger.get().logw(TAG, "Already stopped, no-op.");
      return;
    }
    RotatingFileLogger.get().logi(TAG, "Stopping to run.");
    running.set(false);
    if (eegSampleSubscription != null) {
      eegSampleSubscription.cancel();
    }
    if (activeSessionSubscription != null) {
      activeSessionSubscription.cancel();
    }
    if (waitForDataTimer != null) {
      waitForDataTimer.purge();
      waitForDataTimer.cancel();
      waitForDataTimer = null;
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
        RotatingFileLogger.get().loge(TAG, "Error when stopping. " + e.getMessage() + " " +
                Arrays.toString(e.getStackTrace()));
      } catch (InterruptedException e) {
        Thread.currentThread().interrupt();
      }
    }
    if (executor != null) {
      executor.shutdown();
    }
    RotatingFileLogger.get().logi(TAG, "Stopped running.");
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
    if (sessionEegSamplesCount - localSession.getEegSamplesUploaded() >=
        localSession.getEegSampleRate() * uploadChunkSize.getSeconds()) {
      List<EegSample> eegSamples = objectBoxDatabase.getEegSamples(
          localSession.id, relativeEegStartOffset,
          (long)localSession.getEegSampleRate() * uploadChunkSize.getSeconds());
      if (eegSamples != null && !eegSamples.isEmpty()) {
        eegSamplesToUpload.addAll(eegSamples);
      }
    } else {
      LocalSession refreshedLocalSession = objectBoxDatabase.getLocalSession(localSession.id);
      // If null, already deleted (Upload complete).
      if (refreshedLocalSession != null && (
          refreshedLocalSession.getStatus() == LocalSession.Status.FINISHED ||
          refreshedLocalSession.getStatus() == LocalSession.Status.ALL_DATA_RECEIVED)) {
        List<EegSample> eegSamples =
                objectBoxDatabase.getLastEegSamples(localSession.id, /*count=*/1);
        if (!eegSamples.isEmpty() && Instant.now().isAfter(
                  eegSamples.get(0).getReceptionTimestamp().plus(Duration.ofSeconds(1)))) {
          RotatingFileLogger.get().logv(TAG, "Session finished, adding samples to upload.");
          eegSamplesToUpload.addAll(objectBoxDatabase.getEegSamples(localSession.id,
                  relativeEegStartOffset,
                  sessionEegSamplesCount - localSession.getEegSamplesUploaded()));
          if (eegSamplesToUpload.isEmpty()) {
            // Nothing to upload, marking it as UPLOADED.
            RotatingFileLogger.get().logd(TAG, "Session " + localSession.id + "" +
                " upload is completed.");
            localSession.setStatus(LocalSession.Status.UPLOADED);
            completeSession(localSession);
            // This could be deleted at a later time in case the data needs to be analyzed or
            // displayed in the app.
            objectBoxDatabase.deleteLocalSession(localSession.id);
          }
        }
      }
    }
    samplesToUpload.put(EEG_SAMPLES, eegSamplesToUpload);

    List<BaseRecord> accelerationsToUpload = new ArrayList<>();
    long relativeAccStartOffset = localSession.getAccelerationsUploaded() -
        localSession.getAccelerationsDeleted();
    long sessionAccSamplesCount = objectBoxDatabase.getAccelerationCount(localSession.id) +
        localSession.getAccelerationsDeleted();
    if (sessionAccSamplesCount - localSession.getAccelerationsUploaded() >=
        localSession.getAccelerationSampleRate() * uploadChunkSize.getSeconds()) {
      accelerationsToUpload.addAll(objectBoxDatabase.getAccelerations(
          localSession.id, relativeAccStartOffset,
          (long) localSession.getAccelerationSampleRate() * uploadChunkSize.getSeconds()));
    } else {
      LocalSession refreshedLocalSession = objectBoxDatabase.getLocalSession(localSession.id);
      if (refreshedLocalSession != null && (
          refreshedLocalSession.getStatus() == LocalSession.Status.FINISHED ||
          refreshedLocalSession.getStatus() == LocalSession.Status.ALL_DATA_RECEIVED)) {
        accelerationsToUpload.addAll(objectBoxDatabase.getAccelerations(localSession.id,
                relativeAccStartOffset,
                sessionAccSamplesCount - localSession.getAccelerationsUploaded()));
      }
    }
    samplesToUpload.put(ACC_SAMPLES, accelerationsToUpload);

    long deviceInternalStatesToUploadCount = objectBoxDatabase.getDeviceInternalStateCount() -
            localSession.getDeviceInternalStateUploaded();
    if (deviceInternalStatesToUploadCount >= 1) {
      List<BaseRecord> deviceInternalStatesToUpload = new ArrayList<>(
              objectBoxDatabase.getSessionDeviceInternalStates(
              localSession.id, localSession.getDeviceInternalStateUploaded(),
              deviceInternalStatesToUploadCount > localSession.getEegSampleRate() *
                  uploadChunkSize.getSeconds() ?
                  (long)localSession.getEegSampleRate() * uploadChunkSize.getSeconds() :
                      deviceInternalStatesToUploadCount));
      samplesToUpload.put(INT_STATE_SAMPLES, deviceInternalStatesToUpload);
    }

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
    return (dataSamplesMap.get(EEG_SAMPLES) != null && !dataSamplesMap.get(EEG_SAMPLES).isEmpty());
  }

  // If the app is shutdown suddenly, some sessions that were recording might not have been marked
  // as finished. Mark them as finished so that hte remaining data is uploaded and they are not
  // confused as currently recording by the application.
  private void cleanActiveSessions() {
    List<LocalSession> recordingSessions = objectBoxDatabase.getActiveSessions();
    for (LocalSession session : recordingSessions) {
      session.setStatus(LocalSession.Status.FINISHED);
      objectBoxDatabase.putLocalSession(session);
    }
  }

  private void uploadData() {
    while (running.get()) {
      List<LocalSession> localSessions = objectBoxDatabase.getLocalSessions();
      RotatingFileLogger.get().logd(TAG, "There are " + localSessions.size() +
          " local sessions in the DB.");
      for (LocalSession localSession : localSessions) {
        if (!localSession.isUploadNeeded() || (
            localSession.getStatus() != LocalSession.Status.RECORDING &&
            localSession.getStatus() != LocalSession.Status.ALL_DATA_RECEIVED &&
            localSession.getStatus() != LocalSession.Status.FINISHED)) {
          continue;
        }
         RotatingFileLogger.get().logd(TAG, "Session " + localSession.id + " has " +
            localSession.getEegSamplesUploaded() + " uploaded.");
        Map<String, List<BaseRecord>> samplesToUpload = getSamplesToUpload(localSession);

        while (dataToUpload(samplesToUpload) && running.get()) {
          boolean uploaded = false;
          List<BaseRecord> eegSamplesToUpload = samplesToUpload.get(EEG_SAMPLES);
          RotatingFileLogger.get().logv(TAG, "Session " + localSession.id + " has " +
              eegSamplesToUpload.size() + " eeg records to upload.");
          for (int eegSamplesIndex = 0; eegSamplesIndex < eegSamplesToUpload.size();
              eegSamplesIndex += localSession.getEegSampleRate() * uploadChunkSize.getSeconds()) {
            int eegSamplesEndIndex =
                Math.min(eegSamplesToUpload.size(), eegSamplesIndex +
                    (int)(localSession.getEegSampleRate() * uploadChunkSize.getSeconds()));
            Map<String, List<BaseRecord>> samplesChunkToUpload = new HashMap<>();
            samplesChunkToUpload.put(EEG_SAMPLES,
                eegSamplesToUpload.subList(eegSamplesIndex, eegSamplesEndIndex));
            if (samplesToUpload.containsKey(ACC_SAMPLES) &&
                samplesToUpload.get(ACC_SAMPLES).size() >= eegSamplesIndex + eegSamplesEndIndex) {
              samplesChunkToUpload.put(ACC_SAMPLES,
                  samplesToUpload.get(ACC_SAMPLES).subList(eegSamplesIndex, eegSamplesEndIndex));
            }
            if (samplesToUpload.containsKey(INT_STATE_SAMPLES)) {
              samplesChunkToUpload.put(INT_STATE_SAMPLES, samplesToUpload.get(INT_STATE_SAMPLES));
            }
            DataSamplesProto.DataSamples dataSamplesProto =
                serializeToProto(samplesChunkToUpload, localSession);
            if (saveTestProtoData) {
              saveData(dataSamplesProto);
            }
            uploaded = uploadDataSamplesProto(dataSamplesProto);
          }

          // Update the local database with the uploaded records size and mark the local session as
          // uploaded if done.
          if (uploaded) {
            final int eegSamplesToUploadSize = eegSamplesToUpload.size();
            final int accelerationsToUploadSize = samplesToUpload.containsKey(ACC_SAMPLES) &&
                    samplesToUpload.get(ACC_SAMPLES) != null ?
                    samplesToUpload.get(ACC_SAMPLES).size() : 0;
            final int deviceInternalStateToUploadSize =
                    samplesToUpload.get(INT_STATE_SAMPLES) != null ?
                    samplesToUpload.get(INT_STATE_SAMPLES).size() : 0;
            objectBoxDatabase.runInTx(() -> {
              localSession.setEegSamplesUploaded(
                  localSession.getEegSamplesUploaded() + eegSamplesToUploadSize);
              localSession.setAccelerationsUploaded(
                  localSession.getAccelerationsUploaded() + accelerationsToUploadSize);
              localSession.setDeviceInternalStateUploaded(
                      localSession.getDeviceInternalStateUploaded() +
                              deviceInternalStateToUploadSize);
              RotatingFileLogger.get().logv(TAG, "Uploaded " + localSession.getEegSamplesUploaded() +
                  " eeg samples from session " + localSession.id);
              // Need to check the status from the DB as it could get updated to finished in another
              // thread.
              LocalSession refreshedLocalSession =
                      objectBoxDatabase.getLocalSession(localSession.id);
              if (refreshedLocalSession != null) {
                localSession.setStatus(refreshedLocalSession.getStatus());
              }
              if ((localSession.getStatus() == LocalSession.Status.FINISHED ||
                  localSession.getStatus() == LocalSession.Status.ALL_DATA_RECEIVED) &&
                  localSession.getEegSamplesUploaded() ==
                      objectBoxDatabase.getEegSamplesCount(localSession.id) +
                          localSession.getEegSamplesDeleted()) {
                // TODO(eric): Seems to have an issue where acceleration could be missing sometimes,
                //             should not block completion.
                // localSession.getAccelerationsUploaded() ==
                //         objectBoxDatabase.getAccelerationCount(localSession.id) +
                //                 localSession.getAccelerationsDeleted()
                RotatingFileLogger.get().logd(TAG, "Session " + localSession.id +
                    " data all received and upload is completed.");
                localSession.setStatus(LocalSession.Status.UPLOADED);
                completeSession(localSession);
              }
              objectBoxDatabase.putLocalSession(localSession);
            });
            if (localSession.getStatus() != LocalSession.Status.UPLOADED) {
              objectBoxDatabase.runInTx(() -> {
                LocalSession refreshedLocalSession = objectBoxDatabase.getLocalSession(
                        localSession.id);
                localSession.setStatus(refreshedLocalSession.getStatus());
                long eegRecordsDeleted = deleteEegOldRecords(localSession);
                long accelerationRecordsDeleted = deleteAccelerationOldRecords(localSession);
                RotatingFileLogger.get().logd(TAG, "Deleted " + eegRecordsDeleted + " eeg records.");
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
      recordsToUpload.set(false);
      RotatingFileLogger.get().logd(TAG, "All upload done, waiting for new samples.");
      // Wait until there are new samples to upload.
      eegSampleSubscription =
          objectBoxDatabase.subscribe(EegSample.class, eegSample -> {
            if (databaseSink.getEegRecordsCounter() > databaseSink.getLastSessionEegFrequency()) {
              RotatingFileLogger.get().logd(TAG, "waking up: " +
                  databaseSink.getEegRecordsCounter());
              databaseSink.resetEegRecordsCounter();
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
        RotatingFileLogger.get().logd(TAG, "active session present, waiting for finished session");
        activeSessionSubscription = subscribeToFinishedSession(activeSessionOptional.get().id);
      } else {
        if (!localSessions.isEmpty() &&
            localSessions.get(localSessions.size() - 1).isUploadNeeded() &&
            (localSessions.get(localSessions.size() - 1).getStatus() ==
            LocalSession.Status.FINISHED ||
            localSessions.get(localSessions.size() - 1).getStatus() ==
            LocalSession.Status.ALL_DATA_RECEIVED)) {
          RotatingFileLogger.get().logd(TAG, "no active session present, waiting for data upload finished timer");
          scheduleDataUploadFinishedTimer(localSessions.get(localSessions.size() - 1).id);
        }
      }

      synchronized (syncToken) {
        while (running.get() && !recordsToUpload.get()) {
          try {
            RotatingFileLogger.get().logd(TAG, "Starting to wait");
            syncToken.wait();
            RotatingFileLogger.get().logd(TAG, "Wait finished");
          } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
          }
        }
      }
      eegSampleSubscription.cancel();
      if (activeSessionSubscription != null) {
        activeSessionSubscription.cancel();
      }
      if (waitForDataTimer != null) {
        waitForDataTimer.purge();
        waitForDataTimer.cancel();
        waitForDataTimer = null;
      }
      RotatingFileLogger.get().logd(TAG, "New records to upload, wait finished.");
    }
  }

  private void saveData(DataSamplesProto.DataSamples dataSamplesProto) {
    saveTestProtoData = false;
    try {
      String collection = "content://media/external/file";
      String relativePath = "Documents/NextSense";

      Uri collectionUri = Uri.parse(collection);

      ContentValues contentValues = new ContentValues();

      contentValues.put(MediaStore.MediaColumns.DISPLAY_NAME,
          "test_proto_" + + System.currentTimeMillis() + ".txt");
      contentValues.put(MediaStore.MediaColumns.MIME_TYPE, "txt/plain");
      contentValues.put(MediaStore.MediaColumns.SIZE, dataSamplesProto.getSerializedSize());
      contentValues.put(MediaStore.MediaColumns.DATE_MODIFIED, Instant.now().getEpochSecond());
      contentValues.put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath);
      contentValues.put(MediaStore.MediaColumns.IS_PENDING, 0);

      Uri fileUri = context.getContentResolver().insert(collectionUri, contentValues);

      OutputStream outputStream = context.getContentResolver().openOutputStream(fileUri);
      Log.w(TAG, "Writing to file: " + fileUri.getPath() + "/test_proto.txt");
      dataSamplesProto.writeTo(outputStream);
      outputStream.close();
    } catch (FileNotFoundException e) {
      RotatingFileLogger.get().logw(TAG, "file not found: " + e.getMessage());
    } catch (IOException e) {
      RotatingFileLogger.get().logw(TAG, "failed to write proto: " + e.getMessage());
    }
  }

  private final DateTimeFormatter formatter =
      DateTimeFormatter.ISO_LOCAL_DATE_TIME.withZone(ZoneId.from(ZoneOffset.UTC));

  private long deleteEegOldRecords(LocalSession localSession) {
    if (objectBoxDatabase.getEegSamplesCount(localSession.id) > minRecordsToKeep) {
      RotatingFileLogger.get().logd(TAG, "Got " +
          objectBoxDatabase.getEegSamplesCount(localSession.id) +
          " eeg records in db, need to delete " +
          (objectBoxDatabase.getEegSamplesCount(localSession.id) - minRecordsToKeep));
      Instant lastSampleTime = objectBoxDatabase.getEegSamples(
          localSession.id, localSession.getEegSamplesUploaded() -
              localSession.getEegSamplesDeleted() - 1L, /*count=*/1)
          .get(0).getAbsoluteSamplingTimestamp();
      Instant cutOffDate = lastSampleTime.minus(minDurationToKeep);
      RotatingFileLogger.get().logd(TAG, "EEG Cutoff time: " + formatter.format(cutOffDate));
      return objectBoxDatabase.deleteFirstEegSamplesData(localSession.id,
          cutOffDate.toEpochMilli());
    }
    return 0;
  }

  private long deleteAccelerationOldRecords(LocalSession localSession) {
    if (objectBoxDatabase.getAccelerationCount(localSession.id) > minRecordsToKeep) {
      RotatingFileLogger.get().logd(TAG, "Got " + objectBoxDatabase.getAccelerationCount(localSession.id) +
          " acceleration records in db, need to delete " +
          (objectBoxDatabase.getAccelerationCount(localSession.id) - minRecordsToKeep));
      Instant lastSampleTime = objectBoxDatabase.getAccelerations(
          localSession.id, localSession.getAccelerationsUploaded() -
              localSession.getAccelerationsDeleted() - 1L, /*count=*/1)
          .get(0).getAbsoluteSamplingTimestamp();
      Instant cutOffDate = lastSampleTime.minus(minDurationToKeep);
      RotatingFileLogger.get().logd(TAG, "Acceleration cutoff time: " + formatter.format(cutOffDate));
      return objectBoxDatabase.deleteFirstAccelerationsData(localSession.id,
          cutOffDate.toEpochMilli());
    }
    return 0;
  }

  private DataSamplesProto.DeviceInternalState serializeToProto(
          DeviceInternalState deviceInternalState) {
    DataSamplesProto.DeviceInternalState.Builder builder =
            DataSamplesProto.DeviceInternalState.newBuilder();
    Timestamp timestamp = Timestamp.newBuilder()
            .setSeconds(deviceInternalState.getTimestamp().getEpochSecond())
            .setNanos(deviceInternalState.getTimestamp().getNano()).build();
    builder.setTimestamp(timestamp);
    builder.setBatteryMilliVolts(deviceInternalState.getBatteryMilliVolts());
    builder.setBusy(deviceInternalState.isBusy());
    builder.setUsdPresent(deviceInternalState.isuSdPresent());
    builder.setHdmiCablePresent(deviceInternalState.isHdmiCablePresent());
    builder.setRtcClockSet(deviceInternalState.isRtcClockSet());
    builder.setCaptureRunning(deviceInternalState.isCaptureRunning());
    builder.setCharging(deviceInternalState.isCharging());
    builder.setBatteryLow(deviceInternalState.isBatteryLow());
    builder.setUsdLoggingEnabled(deviceInternalState.isuSdLoggingEnabled());
    builder.setInternalErrorDetected(deviceInternalState.isInternalErrorDetected());
    builder.setSamplesCounter(deviceInternalState.getSamplesCounter());
    builder.setBleQueueBacklog(deviceInternalState.getBleQueueBacklog());
    builder.setLostSamplesCounter(deviceInternalState.getLostSamplesCounter());
    builder.setBleRssi(deviceInternalState.getBleRssi());
    builder.addAllLeadsOffPositive(deviceInternalState.getLeadsOffPositive());
    return builder.build();
  }

  private DataSamplesProto.EegDataSamples serializeEegToProto(
          Map<String, List<BaseRecord>> samples, LocalSession localSession) {
    // TODO(eric): If acceleration is not on the same frequency as eeg, should send it in a separate
    //             proto?
    List<BaseRecord> eegSamplesToUpload = samples.get(EEG_SAMPLES);
    List<BaseRecord> accelerationsToUpload = samples.get(ACC_SAMPLES);
    if (accelerationsToUpload == null) {
      accelerationsToUpload = new ArrayList<>();
    }
    RotatingFileLogger.get().logv(TAG, "Uploading " + eegSamplesToUpload.size() + " eeg samples.");
    RotatingFileLogger.get().logv(TAG, "Uploading " + accelerationsToUpload.size() +
        " acc samples.");
    DataSamplesProto.EegDataSamples.Builder dataSamplesProtoBuilder =
        DataSamplesProto.EegDataSamples.newBuilder();
    dataSamplesProtoBuilder.setModality(DataSamplesProto.EegDataSamples.Modality.EAR_EEG);
    if (localSession.getEarbudsConfig() != null) {
      dataSamplesProtoBuilder.setEarbudsConfig(localSession.getEarbudsConfig());
    }
    dataSamplesProtoBuilder.setFrequency((int)localSession.getEegSampleRate());
    dataSamplesProtoBuilder.setExpectedSamplesCount(eegSamplesToUpload.size());
    Instant expectedStartInstant = getExpectedFirstEegTimestamp(
        localSession, (EegSample) eegSamplesToUpload.get(0), (int)localSession.getEegSampleRate());
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
                DataSamplesProto.Channel.newBuilder().setName(String.valueOf(channel)));
        channelBuilder.addSample(eegSample.getEegSamples().get(channel));
      }
      if (accelerationsToUpload.size() > i) {
        Acceleration acceleration = (Acceleration) accelerationsToUpload.get(i);
        for (String accChannel : Acceleration.CHANNELS) {
          DataSamplesProto.Channel.Builder channelBuilder = channelBuilders.computeIfAbsent(
                  accChannel, channelValue -> DataSamplesProto.Channel.newBuilder().setName(accChannel));
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
      }
      if (eegSample.getSync() != null) {
        dataSamplesProtoBuilder.addSync(eegSample.getSync());
      }
      if (eegSample.getTrigIn() != null) {
        dataSamplesProtoBuilder.addTrigIn(eegSample.getTrigIn());
      }
      if (eegSample.getTrigOut() != null) {
        dataSamplesProtoBuilder.addTrigOut(eegSample.getTrigOut());
      }
      if (eegSample.getZMod() != null) {
        dataSamplesProtoBuilder.addZMod(eegSample.getZMod());
      }
      if (eegSample.getMarker() != null) {
        dataSamplesProtoBuilder.addMarker(eegSample.getMarker());
      }
      if (eegSample.getButton() != null) {
        dataSamplesProtoBuilder.addButton(eegSample.getButton());
      }
    }
    for (DataSamplesProto.Channel.Builder channelBuilder : channelBuilders.values()) {
      dataSamplesProtoBuilder.addChannel(channelBuilder.build());
    }
    return dataSamplesProtoBuilder.build();
  }

  private DataSamplesProto.DataSamples serializeToProto(
          Map<String, List<BaseRecord>> samples, LocalSession localSession) {
    DataSamplesProto.DataSamples.Builder builder = DataSamplesProto.DataSamples.newBuilder();
    if (localSession.getUserBigTableKey() != null) {
      builder.setUserId(localSession.getUserBigTableKey());
    }
    if (localSession.getCloudDataSessionId() != null) {
      builder.setDataSessionId(localSession.getCloudDataSessionId());
    }
    builder.setEegDataSamples(serializeEegToProto(samples, localSession));
    if (samples.containsKey(INT_STATE_SAMPLES)) {
      for (BaseRecord deviceInternalState : samples.get(INT_STATE_SAMPLES)) {
        builder.addDeviceInternalStates(
                serializeToProto((DeviceInternalState) deviceInternalState));
      }
    }
    return builder.build();
  }

  private boolean uploadDataSamplesProto(DataSamplesProto.DataSamples dataSamplesProto) {
    // Create the arguments to the callable function.
    RotatingFileLogger.get().logi(TAG, "Starting upload with callable function.");
    ByteArrayOutputStream byteArrayOutputStream =
            new ByteArrayOutputStream(dataSamplesProto.getSerializedSize());
    try {
      dataSamplesProto.writeTo(byteArrayOutputStream);
    } catch (IOException e) {
      RotatingFileLogger.get().loge(TAG, "Error serializing proto: " + e.getMessage());
      return false;
    }
    return firebaseFunctions.uploadDataSamples(byteArrayOutputStream);
  }

  private SessionProto.Session serializeSessionToProto(LocalSession localSession) {
    SessionProto.Session.Builder builder = SessionProto.Session.newBuilder();
    if (localSession.getCloudDataSessionId() != null) {
      builder.setId(localSession.getCloudDataSessionId());
    }
    if (localSession.getUserBigTableKey() != null) {
      builder.setBtKey(localSession.getUserBigTableKey());
    }
    if (localSession.getEarbudsConfig() != null) {
      builder.setChannelConfig(localSession.getEarbudsConfig());
    }
    switch (applicationType) {
      case CONSUMER -> builder.setUserType(SessionProto.UserType.USER_TYPE_CONSUMER);
      case RESEARCH -> builder.setUserType(SessionProto.UserType.USER_TYPE_RESEARCHER);
      case MEDICAL -> builder.setUserType(SessionProto.UserType.USER_TYPE_SUBJECT);
    }
    builder.setExpectedSamplesCount(localSession.getEegSamplesUploaded());
    return builder.build();
  }

  public boolean completeSession(LocalSession localSession) {
    RotatingFileLogger.get().logi(TAG, "Starting complete session with callable function.");
    SessionProto.Session sessionProto = serializeSessionToProto(localSession);
    ByteArrayOutputStream byteArrayOutputStream =
            new ByteArrayOutputStream(sessionProto.getSerializedSize());
    try {
      sessionProto.writeTo(byteArrayOutputStream);
    } catch (IOException e) {
      RotatingFileLogger.get().loge(TAG, "Error serializing proto: " + e.getMessage());
      return false;
    }
    boolean completed = firebaseFunctions.completeSession(byteArrayOutputStream);
    // TODO(eric): Have a separate thread try to complete sessions in case there is a transient
    //             failure. That way it can retry until it passes.
    // This could be deleted at a later time in case the data needs to be analyzed or displayed in
    // the app.
    if (completed) {
      localSession.setStatus(LocalSession.Status.COMPLETED);
      objectBoxDatabase.putLocalSession(localSession);
      objectBoxDatabase.deleteLocalSession(localSession.id);
    }
    return completed;
  }

  private DataSubscription subscribeToFinishedSession(long localSessionId) {
    return objectBoxDatabase.getFinishedLocalSession(localSessionId).subscribe()
        .on(subscriptionsScheduler).observer(finishedSessions -> {
          LocalSession finishedSession =
                  objectBoxDatabase.getFinishedLocalSession(localSessionId).findFirst();
          if (finishedSession == null) {
            RotatingFileLogger.get().logd(TAG, "No finished session, not waking up.");
            return;
          }
          RotatingFileLogger.get().logd(TAG,
              "finished session, scheduling data upload finished timer.");
          scheduleDataUploadFinishedTimer(localSessionId);
        });
  }

  private void scheduleDataUploadFinishedTimer(long localSessionId) {
    waitForDataTimer = new Timer();
    TimerTask checkTransmissionFinishedTask = new TimerTask() {
      @Override
      public void run() {
        RotatingFileLogger.get().logi(TAG, "checking is upload finish to send remaining data.");
        // Check if the most recent record of that finished session is over a second old. If that
        // is the case then the upload from the device is considered finished.
        List<EegSample> eegSamples =
                objectBoxDatabase.getLastEegSamples(localSessionId, /*count=*/1);
        if (!eegSamples.isEmpty() && Instant.now().isAfter(
            eegSamples.get(0).getReceptionTimestamp().plus(Duration.ofSeconds(1)))) {
            RotatingFileLogger.get().logd(TAG,
                "Session " + localSessionId + " data all received, waking Uploader.");
            LocalSession localSession = objectBoxDatabase.getLocalSession(localSessionId);
            localSession.setStatus(LocalSession.Status.ALL_DATA_RECEIVED);
            objectBoxDatabase.putLocalSession(localSession);
            databaseSink.resetEegRecordsCounter();
            recordsToUpload.set(true);
            waitForDataTimer.cancel();
            synchronized (syncToken) {
              syncToken.notifyAll();
            }
        }
      }
    };
    waitForDataTimer.scheduleAtFixedRate(checkTransmissionFinishedTask,
        /*delay=*/Duration.ofSeconds(1).toMillis(), Duration.ofSeconds(1).toMillis());
  }

  private void onConnectivityStateChanged() {
    if (currentConnectivityState == Connectivity.State.FULL_CONNECTION ||
        currentConnectivityState == minimumConnectivityState) {
      RotatingFileLogger.get().logi(TAG, "Connectivity state changed to " +
              currentConnectivityState + ", starting uploader.");
      startRunning();
    } else {
      RotatingFileLogger.get().logi(TAG,
          "Connectivity state changed to " + currentConnectivityState +
              " which is under the threshold, stopping uploader.");
      stopRunning();
    }
  }

  private final Connectivity.StateListener connectivityStateListener = newState -> {
    currentConnectivityState = newState;
    onConnectivityStateChanged();
  };
}
