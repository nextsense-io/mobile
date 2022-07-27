package io.nextsense.android.base.data;

import android.os.Environment;
import android.os.HandlerThread;
import android.util.Log;

import androidx.annotation.Nullable;

import com.google.protobuf.Timestamp;

import java.io.ByteArrayOutputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
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

import io.nextsense.android.base.DataSamplesProto;
import io.nextsense.android.base.SessionProto;
import io.nextsense.android.base.communication.firebase.CloudFunctions;
import io.nextsense.android.base.communication.internet.Connectivity;
import io.nextsense.android.base.db.objectbox.ObjectBoxDatabase;
import io.nextsense.android.base.utils.Util;
import io.objectbox.android.AndroidScheduler;
import io.objectbox.query.Query;
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

  private final ObjectBoxDatabase objectBoxDatabase;
  private final CloudFunctions firebaseFunctions;
  private final Connectivity connectivity;
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
  // Once the session is marked as finished, run a timer to see when all data is transferred. Once
  // that is done, can upload the remaining data that is less than the chunk size.
  private Timer waitForDataTimer;
  private boolean started;
  private Connectivity.State minimumConnectivityState = Connectivity.State.FULL_CONNECTION;
  private Connectivity.State currentConnectivityState = Connectivity.State.NO_CONNECTION;
  // Used to generate test data manually, should always be false in production.
  private boolean saveData = false;

  private Uploader(ObjectBoxDatabase objectBoxDatabase, Connectivity connectivity,
                   int uploadChunkSize, int minRecordsToKeep, Duration minDurationToKeep) {
    this.objectBoxDatabase = objectBoxDatabase;
    this.connectivity = connectivity;
    this.uploadChunkSize = uploadChunkSize;
    this.minRecordsToKeep = minRecordsToKeep;
    this.minDurationToKeep = minDurationToKeep;
    this.firebaseFunctions = CloudFunctions.create();
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
    cleanActiveSessions();
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
        Log.e(TAG, "Error when stopping. " + e.getMessage() + " " +
                Arrays.toString(e.getStackTrace()));
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
    } else {
      LocalSession refreshedLocalSession = objectBoxDatabase.getLocalSession(localSession.id);
      // If null, already deleted (Upload complete).
      if (refreshedLocalSession != null && refreshedLocalSession.getStatus() ==
              LocalSession.Status.FINISHED) {
        List<EegSample> eegSamples =
                objectBoxDatabase.getLastEegSamples(localSession.id, /*count=*/1);
        if (!eegSamples.isEmpty() && Instant.now().isAfter(
                  eegSamples.get(0).getReceptionTimestamp().plus(Duration.ofSeconds(1)))) {
          Util.logv(TAG, "Session finished, adding samples to upload.");
          eegSamplesToUpload.addAll(objectBoxDatabase.getEegSamples(localSession.id,
                  relativeEegStartOffset,
                  sessionEegSamplesCount - localSession.getEegSamplesUploaded()));
          if (eegSamplesToUpload.isEmpty()) {
            // Nothing to upload, marking it as UPLOADED.
            Util.logd(TAG, "Session " + localSession.id + " upload is completed.");
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
        localSession.getEegSamplesDeleted();
    long sessionAccSamplesCount = objectBoxDatabase.getAccelerationCount(localSession.id) +
        localSession.getAccelerationsDeleted();
    if (sessionAccSamplesCount - localSession.getAccelerationsUploaded() >= uploadChunkSize) {
      accelerationsToUpload.addAll(objectBoxDatabase.getAccelerations(
          localSession.id, relativeAccStartOffset, uploadChunkSize));
    } else {
      LocalSession refreshedLocalSession = objectBoxDatabase.getLocalSession(localSession.id);
      if (refreshedLocalSession != null && refreshedLocalSession.getStatus() ==
              LocalSession.Status.FINISHED) {
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
              deviceInternalStatesToUploadCount > uploadChunkSize ? uploadChunkSize :
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

        while (dataToUpload(samplesToUpload) && running.get()) {
          boolean uploaded = false;
          List<BaseRecord> eegSamplesToUpload = samplesToUpload.get(EEG_SAMPLES);
          Util.logv(TAG, "Session " + localSession.id + " has " + eegSamplesToUpload.size() +
                  " eeg records to upload.");
          for (int eegSamplesIndex = 0; eegSamplesIndex < eegSamplesToUpload.size();
              eegSamplesIndex += uploadChunkSize) {
            int eegSamplesEndIndex =
                Math.min(eegSamplesToUpload.size(), eegSamplesIndex + uploadChunkSize);
            Map<String, List<BaseRecord>> samplesChunkToUpload = new HashMap<>();
            samplesChunkToUpload.put(EEG_SAMPLES,
                eegSamplesToUpload.subList(eegSamplesIndex, eegSamplesEndIndex));
            if (samplesToUpload.containsKey(ACC_SAMPLES) &&
                    samplesToUpload.get(ACC_SAMPLES).size() >=
                            eegSamplesIndex + eegSamplesEndIndex) {
              samplesChunkToUpload.put(ACC_SAMPLES,
                  samplesToUpload.get(ACC_SAMPLES).subList(eegSamplesIndex, eegSamplesEndIndex));
            }
            if (samplesToUpload.containsKey(INT_STATE_SAMPLES)) {
              samplesChunkToUpload.put(INT_STATE_SAMPLES, samplesToUpload.get(INT_STATE_SAMPLES));
            }
            DataSamplesProto.DataSamples dataSamplesProto =
                serializeToProto(samplesChunkToUpload, localSession);
            if (saveData) {
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
              Util.logv(TAG, "Uploaded " + localSession.getEegSamplesUploaded() +
                  " eeg samples from session " + localSession.id);
              // Need to check the status from the DB as it could get updated to finished in another
              // thread.
              LocalSession refreshedLocalSession =
                      objectBoxDatabase.getLocalSession(localSession.id);
              if (refreshedLocalSession != null) {
                localSession.setStatus(refreshedLocalSession.getStatus());
              }
              if (localSession.getStatus() ==
                  LocalSession.Status.FINISHED && localSession.getEegSamplesUploaded() ==
                      objectBoxDatabase.getEegSamplesCount(localSession.id) +
                          localSession.getEegSamplesDeleted()) {
                // TODO(eric): Seems to have an issue where acceleration could be missing sometimes,
                //             should not block completion.
                // localSession.getAccelerationsUploaded() ==
                //         objectBoxDatabase.getAccelerationCount(localSession.id) +
                //                 localSession.getAccelerationsDeleted()
                Util.logd(TAG, "Session " + localSession.id + " upload is completed.");
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
            if (recordsSinceLastNotify > uploadChunkSize) {
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
      } else {
        if (!localSessions.isEmpty() &&
            localSessions.get(localSessions.size() - 1).isUploadNeeded()) {
          scheduleDataUploadFinishedTimer(localSessions.get(localSessions.size() - 1).id);
        }
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
      if (waitForDataTimer != null) {
        waitForDataTimer.purge();
        waitForDataTimer.cancel();
        waitForDataTimer = null;
      }
      Util.logd(TAG, "New records to upload, wait finished.");
    }
  }

  private void saveData(DataSamplesProto.DataSamples dataSamplesProto) {
    saveData = false;
    try {
      FileOutputStream output = new FileOutputStream(
              Environment.getExternalStorageDirectory().getPath() + "/test_proto.txt");
      dataSamplesProto.writeTo(output);
    } catch (FileNotFoundException e) {
      Log.w(TAG, "file not found: " + e.getMessage());
    } catch (IOException e) {
      Log.w(TAG, "failed to write proto: " + e.getMessage());
    }
  }

  private final DateTimeFormatter formatter =
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
      Util.logd(TAG, "Acceleration cutoff time: " + formatter.format(cutOffDate));
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
    Util.logv(TAG, "Uploading " + eegSamplesToUpload.size() + " eeg samples.");
    Util.logv(TAG, "Uploading " + accelerationsToUpload.size() + " acc samples.");
    DataSamplesProto.EegDataSamples.Builder dataSamplesProtoBuilder =
        DataSamplesProto.EegDataSamples.newBuilder();
    dataSamplesProtoBuilder.setModality(DataSamplesProto.EegDataSamples.Modality.EAR_EEG);
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
    Log.i(TAG, "Starting upload with callable function.");
    ByteArrayOutputStream byteArrayOutputStream =
            new ByteArrayOutputStream(dataSamplesProto.getSerializedSize());
    try {
      dataSamplesProto.writeTo(byteArrayOutputStream);
    } catch (IOException e) {
      Log.e(TAG, "Error serializing proto: " + e.getMessage());
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
    builder.setExpectedSamplesCount(localSession.getEegSamplesUploaded());
    return builder.build();
  }

  public boolean completeSession(LocalSession localSession) {
    Log.i(TAG, "Starting complete session with callable function.");
    SessionProto.Session sessionProto = serializeSessionToProto(localSession);
    ByteArrayOutputStream byteArrayOutputStream =
            new ByteArrayOutputStream(sessionProto.getSerializedSize());
    try {
      sessionProto.writeTo(byteArrayOutputStream);
    } catch (IOException e) {
      Log.e(TAG, "Error serializing proto: " + e.getMessage());
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
            Util.logd(TAG, "No finished session, not waking up.");
            return;
          }
          scheduleDataUploadFinishedTimer(localSessionId);
        });
  }

  private void scheduleDataUploadFinishedTimer(long localSessionId) {
    waitForDataTimer = new Timer();
    TimerTask checkTransmissionFinishedTask = new TimerTask() {
      @Override
      public void run() {
        Log.i(TAG, "checking is upload finish to send remaining data.");
        // Check if the most recent record of that finished session is over a second old. If that
        // is the case then the upload from the device is considered finished.
        List<EegSample> eegSamples =
                objectBoxDatabase.getLastEegSamples(localSessionId, /*count=*/1);
        if (!eegSamples.isEmpty()) {
          if (Instant.now().isAfter(
                  eegSamples.get(0).getReceptionTimestamp().plus(Duration.ofSeconds(1)))) {
            Util.logd(TAG, "Session " + localSessionId + " finished, waking Uploader.");
            recordsSinceLastNotify = 0;
            recordsToUpload.set(true);
            synchronized (syncToken) {
              syncToken.notifyAll();
            }
          }
        } else {
          Log.i(TAG, "Empty session, no need to keep checking.");
          waitForDataTimer.purge();
          waitForDataTimer.cancel();
          waitForDataTimer = null;
        }
      }
    };
    waitForDataTimer.scheduleAtFixedRate(checkTransmissionFinishedTask, /*delay=*/0,
            Duration.ofSeconds(1).toMillis());
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
