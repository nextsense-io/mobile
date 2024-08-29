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
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.stream.Collectors;

import io.nextsense.android.ApplicationType;
import io.nextsense.android.base.DataSamplesProto;
import io.nextsense.android.base.DataSamplesProto.ModalityDataSamples.Modality;
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
  private static final Duration UPLOAD_SAFETY_MARGIN = Duration.ofSeconds(10);

  // Should be 1 second of data to be simple to import in BigTable.
  private final Duration uploadChunkSize;
  private final Context context;
  private final ApplicationType applicationType;
  private final ObjectBoxDatabase objectBoxDatabase;
  private final DatabaseSink databaseSink;
  private final CloudFunctions firebaseFunctions;
  private final Connectivity connectivity;
  private final AtomicBoolean running = new AtomicBoolean(false);
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
  private boolean saveTestProtoData = true;

  private Uploader(Context context, ApplicationType applicationType,
                   ObjectBoxDatabase objectBoxDatabase, DatabaseSink databaseSink,
                   Connectivity connectivity, Duration uploadChunkSize, Duration minDurationToKeep) {
    this.context = context;
    this.objectBoxDatabase = objectBoxDatabase;
    this.databaseSink = databaseSink;
    this.connectivity = connectivity;
    this.uploadChunkSize = uploadChunkSize;
    this.minDurationToKeep = minDurationToKeep;
    this.firebaseFunctions = CloudFunctions.create();
    this.applicationType = applicationType;
  }

  public static Uploader create(
      Context context, ApplicationType applicationType, ObjectBoxDatabase objectBoxDatabase,
      DatabaseSink databaseSink, Connectivity connectivity, Duration uploadChunkSize,
      Duration minDurationToKeep) {
    return new Uploader(context, applicationType, objectBoxDatabase, databaseSink, connectivity,
        uploadChunkSize, minDurationToKeep);
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
      eegSampleSubscription = null;
    }
    if (activeSessionSubscription != null) {
      activeSessionSubscription.cancel();
      activeSessionSubscription = null;
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
  private Map<Modality, List<BaseRecord>> getSamplesToUpload(LocalSession localSession) {
    Map<Modality, List<BaseRecord>> samplesToUpload = new HashMap<>();
    List<BaseRecord> eegSamplesToUpload = new ArrayList<>();
    long relativeEegStartOffset = localSession.getEegSamplesUploaded() -
        localSession.getEegSamplesDeleted();
    long sessionEegSamplesCount = objectBoxDatabase.getEegSamplesCount(localSession.id) +
        localSession.getEegSamplesDeleted();
    // TODO(eric): Fix for Xenon not *2.
    if (sessionEegSamplesCount - localSession.getEegSamplesUploaded() >=
        localSession.getEegSampleRate() * uploadChunkSize.getSeconds() * 2) {
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
            RotatingFileLogger.get().logd(TAG, "Session " + localSession.id +
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
    samplesToUpload.put(Modality.EAR_EEG, eegSamplesToUpload);

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
    samplesToUpload.put(Modality.ACC, accelerationsToUpload);

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
      samplesToUpload.put(Modality.INTERNAL_STATE, deviceInternalStatesToUpload);
    }

    return samplesToUpload;
  }

  private Map<Modality, List<BaseRecord>> getSamplesToUploadRelative(LocalSession localSession) {
    Map<Modality, List<BaseRecord>> samplesToUpload = new HashMap<>();
    List<BaseRecord> eegSamplesToUpload = new ArrayList<>();
    List<BaseRecord> accelerationsToUpload = new ArrayList<>();
    List<BaseRecord> angSpeedsToUpload = new ArrayList<>();
    LocalSession refreshedLocalSession = objectBoxDatabase.getLocalSession(localSession.id);
    if (refreshedLocalSession == null) {
      // If null, upload already complete.
      return samplesToUpload;
    }

    // Calculate start and end time offsets for the eeg samples.
    long relativeStartOffset = localSession.getUploadedUntilRelative();
    if (relativeStartOffset == 0) {
      // If the session is new, get the first sample to know the start offset.
      List<EegSample> firstEegSampleList = objectBoxDatabase.getEegSamples(
          localSession.id, /*offset=*/0, /*count=*/1);
      if (firstEegSampleList != null && !firstEegSampleList.isEmpty()) {
        relativeStartOffset = firstEegSampleList.get(0).getRelativeSamplingTimestamp();
      }
    } else {
      // Move the start offset to the next sample.
      relativeStartOffset += (long) (1000f / localSession.getEegSampleRate());
    }
    // Add the upload chunk size in milliseconds to the start offset to get the end time. End time
    // is inclusive, so need to remove 1 millisecond to get the correct end time.
    long relativeEndOffset = relativeStartOffset + uploadChunkSize.toMillis() - 1;

    // Check the absolute time to know if anything needs to be uploaded even if timestamps from the
    // device are relative.
    if (Instant.now().isAfter(localSession.getUploadedUntil().plus(uploadChunkSize)
        .plus(UPLOAD_SAFETY_MARGIN))) {
      Instant startDbRead = Instant.now();
      List<EegSample> eegSamples = objectBoxDatabase.getEegSamplesBetweenRelative(
          localSession.id, relativeStartOffset, relativeEndOffset);
      Log.i(TAG, "Time to get eeg samples: " +
          Duration.between(startDbRead, Instant.now()).toMillis() + "ms");
      if (eegSamples != null && !eegSamples.isEmpty()) {
        eegSamplesToUpload.addAll(eegSamples);
      }
      List<Acceleration> accelerations = objectBoxDatabase.getAccelerationsBetweenRelative(
          localSession.id, relativeStartOffset, relativeEndOffset);
      if (accelerations != null && !accelerations.isEmpty()) {
        accelerations.sort(Comparator.comparing(Acceleration::getRelativeSamplingTimestamp));
        Acceleration previous = null;
        for (Acceleration acceleration : accelerations) {
          if (previous == null) {
            previous = acceleration;
            continue;
          }
          if (Math.abs(acceleration.getRelativeSamplingTimestamp() - previous.getRelativeSamplingTimestamp()) > 10) {
            Log.w(TAG, "Acceleration timestamp difference is not 10ms: Now: " +
                acceleration.getRelativeSamplingTimestamp() + " - Previous " +
                previous.getRelativeSamplingTimestamp() + " = " +
                (acceleration.getRelativeSamplingTimestamp() - previous.getRelativeSamplingTimestamp()));
          }
          previous = acceleration;
        }
        accelerationsToUpload.addAll(accelerations);
      } else {
        if (eegSamples != null && !eegSamples.isEmpty()) {
          RotatingFileLogger.get().logd(TAG, "EEG but not accelerations to upload.");
        }
      }
      List<AngularSpeed> angSpeeds = objectBoxDatabase.getAngularSpeedsBetweenRelative(
          localSession.id, relativeStartOffset, relativeEndOffset);
      if (angSpeeds != null && !angSpeeds.isEmpty()) {
        angSpeedsToUpload.addAll(angSpeeds);
      }
    } else if (refreshedLocalSession.getStatus() == LocalSession.Status.FINISHED ||
        refreshedLocalSession.getStatus() == LocalSession.Status.ALL_DATA_RECEIVED) {
      List<EegSample> eegSamples =
          objectBoxDatabase.getLastEegSamples(localSession.id, /*count=*/1);
      if (!eegSamples.isEmpty() && Instant.now().isAfter(
          eegSamples.get(0).getReceptionTimestamp().plus(Duration.ofSeconds(1)))) {
        RotatingFileLogger.get().logv(TAG, "Session finished, adding samples to upload.");
        eegSamplesToUpload.addAll(objectBoxDatabase.getEegSamplesBetweenRelative(
            localSession.id, relativeStartOffset, relativeEndOffset));
        accelerationsToUpload.addAll(objectBoxDatabase.getAccelerationsBetweenRelative(
            localSession.id, relativeStartOffset, relativeEndOffset));
        angSpeedsToUpload.addAll(objectBoxDatabase.getAngularSpeedsBetweenRelative(
            localSession.id, relativeStartOffset, relativeEndOffset));
        if (eegSamplesToUpload.isEmpty()) {
          // Nothing to upload, marking it as UPLOADED.
          RotatingFileLogger.get().logd(TAG, "Session " + localSession.id +
              " upload is completed.");
          localSession.setStatus(LocalSession.Status.UPLOADED);
          completeSession(localSession);
          // This could be deleted at a later time in case the data needs to be analyzed or
          // displayed in the app.
          objectBoxDatabase.deleteLocalSession(localSession.id);
        }
      }
    }
    samplesToUpload.put(Modality.EAR_EEG, eegSamplesToUpload);
    samplesToUpload.put(Modality.ACC, accelerationsToUpload);
    samplesToUpload.put(Modality.GYRO, angSpeedsToUpload);

    // Upload device internal states for Xenon if any.
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
      samplesToUpload.put(Modality.INTERNAL_STATE, deviceInternalStatesToUpload);
    }

    return samplesToUpload;
  }

  private @Nullable Instant getExpectedFirstTimestamp(
      LocalSession localSession, TimestampedDataSample firstSampleToUpload, int samplingRate) {
    TimestampedDataSample lastUploadedSample = null;
    if (firstSampleToUpload instanceof EegSample) {
      if (localSession.getEegSamplesUploaded() > 0) {
        List<EegSample> lastUploadedSampleList = objectBoxDatabase.getEegSamples(
                localSession.id, localSession.getEegSamplesUploaded() -
                    localSession.getEegSamplesDeleted() - 1L, /*count=*/1);
        if (lastUploadedSampleList != null && !lastUploadedSampleList.isEmpty()) {
          lastUploadedSample = lastUploadedSampleList.get(0);
        }
      }
    } else if (firstSampleToUpload instanceof Acceleration ||
        firstSampleToUpload instanceof AngularSpeed) {
      if (localSession.getAccelerationsUploaded() > 0) {
        List<Acceleration> lastUploadedSampleList = objectBoxDatabase.getAccelerations(
                localSession.id, localSession.getAccelerationsUploaded() -
                    localSession.getAccelerationsDeleted() - 1L, /*count=*/1);
        if (lastUploadedSampleList != null && !lastUploadedSampleList.isEmpty()) {
          lastUploadedSample = lastUploadedSampleList.get(0);
        }
      }
    }

    // Return the expected first timestamp based on the last uploaded sample, if any. If this is the
    // first upload, send the first sample timestamp.
    long oneSampleDurationMs = Math.round(Math.floor(1000f / samplingRate));
    if (lastUploadedSample != null) {
      if (lastUploadedSample.getAbsoluteSamplingTimestamp() != null) {
        return lastUploadedSample.getAbsoluteSamplingTimestamp().plusMillis(oneSampleDurationMs);
      }
      return getSamplingTimestamp(lastUploadedSample, localSession);
    } else if (firstSampleToUpload.getAbsoluteSamplingTimestamp() != null) {
      return firstSampleToUpload.getAbsoluteSamplingTimestamp();
    }
    return getSamplingTimestamp(firstSampleToUpload, localSession);
  }

  private boolean dataToUpload(Map<Modality, List<BaseRecord>> dataSamplesMap) {
    return (dataSamplesMap.get(Modality.EAR_EEG) != null && 
        !dataSamplesMap.get(Modality.EAR_EEG).isEmpty());
  }

  // If the app is shutdown suddenly, some sessions that were recording might not have been marked
  // as finished. Mark them as finished so that the remaining data is uploaded and they are not
  // confused as currently recording by the application.
  private void cleanActiveSessions() {
    List<LocalSession> recordingSessions = objectBoxDatabase.getUnfinishedSessions();
    for (LocalSession session : recordingSessions) {
      RotatingFileLogger.get().logd(TAG, "Cleaning session " + session.id +
          " as all data received. It was " + session.getStatus());
      session.setStatus(LocalSession.Status.ALL_DATA_RECEIVED);
      objectBoxDatabase.putLocalSession(session);
    }
  }

  private void uploadData() {
    while (running.get()) {
      try {
        List<LocalSession> localSessions = objectBoxDatabase.getLocalSessions();
        if (localSessions == null) {
          localSessions = new ArrayList<>();
        }
        RotatingFileLogger.get().logd(TAG, "There are " + localSessions.size() +
            " local sessions in the DB.");
        for (LocalSession localSession : localSessions) {
          if (!localSession.isUploadNeeded() || (
              localSession.getStatus() != LocalSession.Status.RECORDING &&
                  localSession.getStatus() != LocalSession.Status.ALL_DATA_RECEIVED &&
                  localSession.getStatus() != LocalSession.Status.FINISHED)) {
            continue;
          }
          RotatingFileLogger.get().logd(TAG, "Session " + localSession.id +
              " uploaded eeg samples until " + localSession.getUploadedUntil() + ".");
          Map<Modality, List<BaseRecord>> samplesToUpload;
          // TODO(eric): Implement xenon config support with absolute timestamps.
          if (Objects.equals(localSession.getEarbudsConfig(), "maui_config")) {
            samplesToUpload = getSamplesToUploadRelative(localSession);
          } else {
            samplesToUpload = getSamplesToUpload(localSession);
          }

          while (dataToUpload(samplesToUpload) && running.get()) {
            final int eegSamplesToUploadSize = samplesToUpload.get(Modality.EAR_EEG).size();
            final int accelerationsToUploadSize = samplesToUpload.containsKey(Modality.ACC) &&
                samplesToUpload.get(Modality.ACC) != null ?
                samplesToUpload.get(Modality.ACC).size() : 0;
            final int deviceInternalStateToUploadSize =
                samplesToUpload.get(Modality.INTERNAL_STATE) != null ?
                    samplesToUpload.get(Modality.INTERNAL_STATE).size() : 0;
            RotatingFileLogger.get().logv(TAG, "Session " + localSession.id + " has " +
                eegSamplesToUploadSize + " eeg records and " + accelerationsToUploadSize +
                " imu records to upload.");

            // Serialize and upload the data.
            boolean isLastPacket = samplesToUpload.get(Modality.EAR_EEG).size() !=
                uploadChunkSize.getSeconds() * localSession.getEegSampleRate();
            DataSamplesProto.DataSamples dataSamplesProto = serializeToProto(samplesToUpload,
                localSession, isLastPacket);
            if (dataSamplesProto.getModalityDataSamplesCount() == 1) {
              Log.d(TAG, "No data to upload, skipping.");
            }
            if (saveTestProtoData) {
              saveData(dataSamplesProto);
            }
            boolean uploaded = uploadDataSamplesProto(dataSamplesProto);

            // Update the local database with the uploaded records size and mark the local session
            // as uploaded if done.
            if (uploaded) {
              final EegSample lastEegSample = (EegSample) samplesToUpload.get(Modality.EAR_EEG).get(
                  eegSamplesToUploadSize - 1);
              objectBoxDatabase.runInTx(() -> {
                // Set numbers of records uploaded.
                localSession.setEegSamplesUploaded(
                    localSession.getEegSamplesUploaded() + eegSamplesToUploadSize);
                localSession.setAccelerationsUploaded(
                    localSession.getAccelerationsUploaded() + accelerationsToUploadSize);
                localSession.setDeviceInternalStateUploaded(
                    localSession.getDeviceInternalStateUploaded() +
                        deviceInternalStateToUploadSize);

                // Set until when records were uploaded.
                if (lastEegSample.getAbsoluteSamplingTimestamp() != null) {
                  localSession.setUploadedUntil(lastEegSample.getAbsoluteSamplingTimestamp());
                } else {
                  localSession.setUploadedUntil(getSamplingTimestamp(lastEegSample, localSession));
                  localSession.setUploadedUntilRelative(lastEegSample.getRelativeSamplingTimestamp());
                }
                RotatingFileLogger.get().logv(TAG, "Uploaded a total of " +
                    localSession.getEegSamplesUploaded() + " eeg samples and " +
                    localSession.getAccelerationsUploaded() + " imu samples from session " +
                    localSession.id);

                objectBoxDatabase.putLocalSession(localSession);

                // Need to check the status from the DB as it could get updated to finished in
                // another thread.
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

              // Check if need to delete older records to keep the database size in check.
              if (localSession.getStatus() != LocalSession.Status.UPLOADED) {
                  LocalSession deletingLocalSession = objectBoxDatabase.getLocalSession(
                      localSession.id);
                  localSession.setStatus(deletingLocalSession.getStatus());
                  long eegRecordsDeleted = deleteEegOldRecords(localSession);
                  long accelerationRecordsDeleted = deleteAccelerationOldRecords(localSession);
                  RotatingFileLogger.get().logd(TAG, "Deleted " + eegRecordsDeleted +
                      " eeg records and " + accelerationRecordsDeleted + " imu records.");
                  if (eegRecordsDeleted > 0 || accelerationRecordsDeleted > 0) {
                    localSession.setEegSamplesDeleted(
                        localSession.getEegSamplesDeleted() + eegRecordsDeleted);
                    localSession.setAccelerationsDeleted(
                        localSession.getAccelerationsDeleted() + accelerationRecordsDeleted);
                    objectBoxDatabase.putLocalSession(localSession);
                  }
              }
            }
            // TODO(eric): Implement more error mitigation strategies:
            //             - backoff retry.
            //             - notifications to user/NextSense.
            // If it did not work, it will try to upload again.
            samplesToUpload = getSamplesToUploadRelative(localSession);
          }
        }
        recordsToUpload.set(false);
        RotatingFileLogger.get().logd(TAG, "All upload done, waiting for new samples.");
        // Wait until there are new samples to upload.
        eegSampleSubscription =
            objectBoxDatabase.subscribe(EegSample.class, eegSample -> {
              // TODO(eric): Adjust for Xenon compatibility.
              if (databaseSink.getEegRecordsCounter() > databaseSink.getLastSessionEegFrequency() *
                  uploadChunkSize.getSeconds() * 2) {
                RotatingFileLogger.get().logd(TAG, "waking up: " +
                    databaseSink.getEegRecordsCounter() + " eeg records to upload.");
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
        if (activeSessionOptional != null && activeSessionOptional.isPresent()) {
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
        if (eegSampleSubscription != null) {
          eegSampleSubscription.cancel();
          eegSampleSubscription = null;
        }
        if (activeSessionSubscription != null) {
          activeSessionSubscription.cancel();
          activeSessionSubscription = null;
        }
        if (waitForDataTimer != null) {
          waitForDataTimer.cancel();
          waitForDataTimer.purge();
          waitForDataTimer = null;
        }
        RotatingFileLogger.get().logd(TAG, "New records to upload, wait finished.");
      } catch (Exception e) {
        RotatingFileLogger.get().loge(TAG, "Error in uploadData: " + e.getMessage() + " " +
            Arrays.toString(e.getStackTrace()));
      }
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
          "test_proto_" + System.currentTimeMillis() + ".txt");
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
    long recordsToKeep = minDurationToKeep.getSeconds() * (long) localSession.getEegSampleRate();
    if (objectBoxDatabase.getEegSamplesCount(localSession.id) > recordsToKeep) {
      RotatingFileLogger.get().logd(TAG, "Got " +
          objectBoxDatabase.getEegSamplesCount(localSession.id) +
          " eeg records in db, need to delete " +
          (objectBoxDatabase.getEegSamplesCount(localSession.id) - recordsToKeep));
      List<EegSample> lastEegSampleList = objectBoxDatabase.getEegSamples(
              localSession.id, localSession.getEegSamplesUploaded() -
                  localSession.getEegSamplesDeleted() - 1L, /*count=*/1);
      if (lastEegSampleList == null && lastEegSampleList.isEmpty()) {
        return 0;
      }
      if (lastEegSampleList.get(0).getAbsoluteSamplingTimestamp() != null) {
        Instant cutOffTimestamp = lastEegSampleList.get(0).getAbsoluteSamplingTimestamp().minus(
            minDurationToKeep);
        RotatingFileLogger.get().logd(TAG, "EEG Cutoff time: " +
            formatter.format(cutOffTimestamp));
        return objectBoxDatabase.deleteFirstEegSamplesData(localSession.id,
            cutOffTimestamp.toEpochMilli());
      }
      long cutOffRelativeTimestamp = lastEegSampleList.get(0).getRelativeSamplingTimestamp() -
          minDurationToKeep.toMillis();
      return objectBoxDatabase.deleteFirstRelativeEegSamplesData(localSession.id,
          cutOffRelativeTimestamp);
    }
    return 0;
  }

  private long deleteAccelerationOldRecords(LocalSession localSession) {
    long recordsToKeep = minDurationToKeep.getSeconds() *
        (long) localSession.getAccelerationSampleRate();
    if (objectBoxDatabase.getAccelerationCount(localSession.id) > recordsToKeep) {
      RotatingFileLogger.get().logd(TAG, "Got " +
          objectBoxDatabase.getAccelerationCount(localSession.id) +
          " acceleration records in db, need to delete " +
          (objectBoxDatabase.getAccelerationCount(localSession.id) - recordsToKeep));
      Acceleration lastAcc = objectBoxDatabase.getAccelerations(
          localSession.id, localSession.getAccelerationsUploaded() -
              localSession.getAccelerationsDeleted() - 1L, /*count=*/1)
          .get(0);

      // Angular speed, if present, should be deleted on the same basis as they are at the same
      // sampling rate.
      if (lastAcc.getAbsoluteSamplingTimestamp() != null) {
        Instant cutOffTimestamp = lastAcc.getAbsoluteSamplingTimestamp().minus(minDurationToKeep);
        RotatingFileLogger.get().logd(TAG, "Acceleration cutoff time: " +
            formatter.format(cutOffTimestamp));
        objectBoxDatabase.deleteFirstAngularSpeedData(localSession.id,
            cutOffTimestamp.toEpochMilli());
        return objectBoxDatabase.deleteFirstAccelerationsData(localSession.id,
            cutOffTimestamp.toEpochMilli());
      }
      long cutOffRelativeTimestamp = lastAcc.getRelativeSamplingTimestamp() -
            minDurationToKeep.toMillis();
      objectBoxDatabase.deleteFirstRelativeAngularSpeedData(localSession.id,
          cutOffRelativeTimestamp);
      return objectBoxDatabase.deleteFirstRelativeAccelerationsData(localSession.id,
          cutOffRelativeTimestamp);
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

  private Instant getSamplingTimestamp(TimestampedDataSample dataSample, LocalSession localSession) {
    if (dataSample.getAbsoluteSamplingTimestamp() != null) {
      return dataSample.getAbsoluteSamplingTimestamp();
    } else {
      // If the absolute timestamp is not available, calculate it based on the relative timestamp.
      // Subtract the first relative timestamp received in the session from the current relative
      // timestamp to get the time elapsed since the session started. Add this to the session start
      // time to get the approximate absolute timestamp.
      return localSession.getStartTime().plus(
          Duration.ofMillis(dataSample.getRelativeSamplingTimestamp() -
              localSession.getFirstRelativeTimestamp()));
    }
  }

  private DataSamplesProto.ModalityDataSamples serializeModalityToProto(
      List<BaseRecord> samples, Modality modality,
      LocalSession localSession, boolean isLastPacket) {
    DataSamplesProto.ModalityDataSamples.Builder dataSamplesProtoBuilder =
        DataSamplesProto.ModalityDataSamples.newBuilder();
    if (samples.isEmpty()) {
      return dataSamplesProtoBuilder.build();
    }

    dataSamplesProtoBuilder.setModality(modality);
    if (modality == Modality.EAR_EEG) {
      if (localSession.getEarbudsConfig() != null) {
        dataSamplesProtoBuilder.setEarbudsConfig(localSession.getEarbudsConfig());
      }
    }

    // Add samples to the proto.
    int samplingRate = 0;
    Map<String, DataSamplesProto.Channel.Builder> channelBuilders = new HashMap<>();
    List<Timestamp> modalitySamplingTimestamps = new ArrayList<>();
    if (modality == Modality.EAR_EEG) {
      samplingRate = (int)localSession.getEegSampleRate();
      for (int i = 0; i < samples.size(); ++i) {
        EegSample eegSample = (EegSample) samples.get(i);
        Instant samplingTimestamp = getSamplingTimestamp(eegSample, localSession);
        Timestamp samplingTimestampProto = Timestamp.newBuilder()
            .setSeconds(samplingTimestamp.getEpochSecond())
            .setNanos(samplingTimestamp.getNano()).build();
        modalitySamplingTimestamps.add(samplingTimestampProto);
        for (Integer channel : eegSample.getEegSamples().keySet()) {
          DataSamplesProto.Channel.Builder channelBuilder = channelBuilders.computeIfAbsent(
              String.valueOf(channel), channelValue ->
                  DataSamplesProto.Channel.newBuilder().setName(String.valueOf(channel)));
          channelBuilder.addSample(eegSample.getEegSamples().get(channel));
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
    } else if (modality == Modality.ACC) {
      samplingRate = (int)localSession.getAccelerationSampleRate();
      for (int i = 0; i < samples.size(); ++i) {
        Acceleration acceleration = (Acceleration) samples.get(i);
        Instant samplingTimestamp = getSamplingTimestamp(acceleration, localSession);
        Timestamp samplingTimestampProto = Timestamp.newBuilder()
            .setSeconds(samplingTimestamp.getEpochSecond())
            .setNanos(samplingTimestamp.getNano()).build();
        modalitySamplingTimestamps.add(samplingTimestampProto);
        Acceleration.Channels.getForDeviceLocation(acceleration.getDeviceLocation()).forEach(
            channel -> channelBuilders.computeIfAbsent(
                channel.getName(), channelName ->
                    DataSamplesProto.Channel.newBuilder().setName(channelName)));
        acceleration.getChannels().forEach((channel, value) ->
          Objects.requireNonNull(channelBuilders.get(channel.getName())).addSample(value)
        );
      }
    } else if (modality == Modality.GYRO) {
      samplingRate = (int)localSession.getAccelerationSampleRate();
      for (int i = 0; i < samples.size(); ++i) {
        AngularSpeed angularSpeed = (AngularSpeed) samples.get(i);
        Instant samplingTimestamp = getSamplingTimestamp(angularSpeed, localSession);
        Timestamp samplingTimestampProto = Timestamp.newBuilder()
            .setSeconds(samplingTimestamp.getEpochSecond())
            .setNanos(samplingTimestamp.getNano()).build();
        modalitySamplingTimestamps.add(samplingTimestampProto);
        AngularSpeed.Channels.getForDeviceLocation(angularSpeed.getDeviceLocation()).forEach(
            channel -> channelBuilders.computeIfAbsent(
                channel.getName(), channelName ->
                    DataSamplesProto.Channel.newBuilder().setName(channelName)));
        angularSpeed.getChannels().forEach((channel, value) ->
            Objects.requireNonNull(channelBuilders.get(channel.getName())).addSample(value)
        );
      }
    }
    channelBuilders.forEach((channel, channelBuilder) ->
        dataSamplesProtoBuilder.addChannel(channelBuilder.build()));

    dataSamplesProtoBuilder.setSamplingRate(samplingRate);

    // Sort and deduplicate the sampling timestamps. This is necessary as the timestamps could be
    // duplicated as they come from both ears.
    modalitySamplingTimestamps = modalitySamplingTimestamps.stream()
        .sorted(Comparator.comparing(Timestamp::getSeconds)
            .thenComparing(Timestamp::getNanos))
        .collect(Collectors.toList());

    // Verify that the timestamps are not duplicated in the same time range based on the modality
    // sampling rate. Don't skip more than one out of 2 as we have 2 devices.
    // This will have the effect of aligning the timestamps from both devices for the same modality,
    // even if they are slightly off. If not acceptable we will need to save the timestamp of
    // individual channels which would add a lot of size to transmissions and storage.
    // The best solution would be to make sure that the accelerometers start as close as possible.
    int minTimeDifference = 1000 / samplingRate;
    boolean skippedLast = false;
    List<Timestamp> modalitySamplingTimestampsDedup = new ArrayList<>();
    for (int i = 0; i < modalitySamplingTimestamps.size(); ++i) {
      if (i == 0) {
        modalitySamplingTimestampsDedup.add(modalitySamplingTimestamps.get(i));
        continue;
      }
      long diff = (Math.abs(modalitySamplingTimestamps.get(i).getSeconds() -
          modalitySamplingTimestamps.get(i - 1).getSeconds()) * 1000) +
          Math.abs(modalitySamplingTimestamps.get(i).getNanos() -
              modalitySamplingTimestamps.get(i - 1).getNanos()) / 1000000;
      if (skippedLast) {
        skippedLast = false;
      } else if (diff < minTimeDifference) {
        skippedLast = true;
        continue;
      }
      modalitySamplingTimestampsDedup.add(modalitySamplingTimestamps.get(i));
    }
    dataSamplesProtoBuilder.addAllSamplingTimestamp(modalitySamplingTimestampsDedup);

    // Set the expected start timestamp and the expected samples count.
    Instant expectedStartInstant = getExpectedFirstTimestamp(
        localSession, (TimestampedDataSample) samples.get(0), samplingRate);
    Timestamp expectedStartTimestamp = Timestamp.newBuilder()
        .setSeconds(expectedStartInstant.getEpochSecond())
        .setNanos(expectedStartInstant.getNano()).build();
    dataSamplesProtoBuilder.setExpectedStartTimestamp(expectedStartTimestamp);
    if (!isLastPacket) {
      dataSamplesProtoBuilder.setExpectedSamplesCount(
          (int) (samplingRate * uploadChunkSize.getSeconds()));
    } else {
      // If it is the last packet, calculate the expected samples count based on the last sample and
      // the expected first sample.
      long expectedSamplesCount;
      TimestampedDataSample lastSample = (TimestampedDataSample) samples.get(samples.size() - 1);
      if (lastSample.getAbsoluteSamplingTimestamp() != null) {
        expectedSamplesCount = (lastSample.getAbsoluteSamplingTimestamp().toEpochMilli() -
            expectedStartInstant.toEpochMilli()) / (1000 / samplingRate);
      } else {
        expectedSamplesCount = (getSamplingTimestamp(lastSample, localSession).toEpochMilli()
            - expectedStartInstant.toEpochMilli()) / (1000 / samplingRate);
      }
      dataSamplesProtoBuilder.setExpectedSamplesCount((int) expectedSamplesCount);
    }

    return dataSamplesProtoBuilder.build();
  }

  private DataSamplesProto.DataSamples serializeToProto(
          Map<Modality, List<BaseRecord>> samples, LocalSession localSession,
          boolean isLastPacket) {
    DataSamplesProto.DataSamples.Builder builder = DataSamplesProto.DataSamples.newBuilder();
    if (localSession.getUserBigTableKey() != null) {
      builder.setUserId(localSession.getUserBigTableKey());
    }
    if (localSession.getCloudDataSessionId() != null) {
      builder.setDataSessionId(localSession.getCloudDataSessionId());
    }
    
    for (Modality modality : samples.keySet()) {
      // Legacy type for Xenon internal state.
      if (modality == Modality.INTERNAL_STATE) {
        if (samples.get(modality) != null && !samples.get(modality).isEmpty()) {
          for (BaseRecord deviceInternalState : samples.get(modality)) {
            builder.addDeviceInternalStates(
                serializeToProto((DeviceInternalState) deviceInternalState));
          }
        }
        continue;
      }
      builder.addModalityDataSamples(serializeModalityToProto(
          samples.get(modality), modality, localSession, isLastPacket));
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
      case CONSUMER_MED_DEVICE -> builder.setUserType(
          SessionProto.UserType.USER_TYPE_CONSUMER_MED_DEVICE);
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
        if (eegSamples != null &&!eegSamples.isEmpty() && Instant.now().isAfter(
            eegSamples.get(0).getReceptionTimestamp().plus(Duration.ofSeconds(1)))) {
            RotatingFileLogger.get().logd(TAG,
                "Session " + localSessionId + " data all received, waking Uploader.");
            LocalSession localSession = objectBoxDatabase.getLocalSession(localSessionId);
            localSession.setStatus(LocalSession.Status.ALL_DATA_RECEIVED);
            objectBoxDatabase.putLocalSession(localSession);
            databaseSink.resetEegRecordsCounter();
            recordsToUpload.set(true);
            if (waitForDataTimer != null) {
              waitForDataTimer.cancel();
              waitForDataTimer.purge();
              waitForDataTimer = null;
            }
            synchronized (syncToken) {
              syncToken.notifyAll();
            }
        }
      }
    };
    waitForDataTimer.schedule(checkTransmissionFinishedTask,
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
