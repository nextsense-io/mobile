package io.nextsense.android.base.data;

import androidx.annotation.Nullable;

import java.time.Instant;

import io.nextsense.android.base.db.objectbox.Converters;
import io.objectbox.annotation.Convert;
import io.objectbox.annotation.Entity;
import io.objectbox.converter.PropertyConverter;

/**
 * Local session stored in the local database for sessions that have not been uploaded yet.
 */
@Entity
public class LocalSession extends BaseRecord {

  public enum Status {
    NOT_STARTED(0),  // Recording not started yet, getting ready.
    RECORDING(1),  // Currently recording samples from the device.
    FINISHED(2),  // Session is finished, new samples should not be acquired anymore.
    UPLOADED(3),  // All samples were uploaded to the cloud.
    COMPLETED(4);  // Session marked as completed in the cloud after the upload is done.

    public final int id;

    Status(int id) {
      this.id = id;
    }
  }

  // User key for BigTable. Can be null if the session is local only.
  @Nullable
  private String userBigTableKey;
  // Session id assigned in the cloud database. Can be null if the session is local only.
  @Nullable
  private String cloudDataSessionId;
  // Earbuds configuration for the NextSense device. Can be null if unknown.
  @Nullable
  private String earbudsConfig;
  @Convert(converter = StatusConverter.class, dbType = Integer.class)
  private Status status;
  private boolean uploadNeeded;

  // If some data was received from the device for this session.
  private boolean receivedData;
  private int eegSamplesUploaded;
  private long eegSamplesDeleted;
  private float eegSampleRate;
  private int accelerationsUploaded;
  private long accelerationsDeleted;
  private float accelerationSampleRate;
  private int deviceInternalStateUploaded;
  @Convert(converter = Converters.InstantConverter.class, dbType = Long.class)
  private Instant startTime;
  @Nullable
  @Convert(converter = Converters.InstantConverter.class, dbType = Long.class)
  private Instant endTime;

  private LocalSession(@Nullable String userBigTableKey, @Nullable String cloudDataSessionId,
                       @Nullable String earbudsConfig, Status status, boolean uploadNeeded,
                       boolean receivedData, int eegSamplesUploaded, long eegSamplesDeleted,
                       float eegSampleRate, int accelerationsUploaded, long accelerationsDeleted,
                       float accelerationSampleRate, int deviceInternalStateUploaded,
                       Instant startTime) {
    super();
    this.userBigTableKey = userBigTableKey;
    this.cloudDataSessionId = cloudDataSessionId;
    this.earbudsConfig = earbudsConfig;
    this.status = status;
    this.uploadNeeded = uploadNeeded;
    this.receivedData = receivedData;
    this.eegSamplesUploaded = eegSamplesUploaded;
    this.eegSamplesDeleted = eegSamplesDeleted;
    this.eegSampleRate = eegSampleRate;
    this.accelerationsUploaded = accelerationsUploaded;
    this.accelerationsDeleted = accelerationsDeleted;
    this.accelerationSampleRate = accelerationSampleRate;
    this.deviceInternalStateUploaded = deviceInternalStateUploaded;
    this.startTime = startTime;
  }

  public static LocalSession create(
      @Nullable String userBigTableKey, @Nullable String cloudDataSessionId,
      @Nullable String earbudsConfig, boolean uploadNeeded, boolean receivedData,
      float eegSampleRate, float accelerationSampleRate, Instant startTime) {
    return new LocalSession(cloudDataSessionId, userBigTableKey, earbudsConfig, Status.RECORDING,
        uploadNeeded, receivedData, /*recordsUploaded=*/0, /*eegSamplesDeleted=*/0, eegSampleRate,
        /*accelerationsUploaded=*/0, /*accelerationSamplesDeleted=*/0, accelerationSampleRate,
        /*deviceInternalStateUploaded=*/0, startTime);
  }

  // Need to be public for ObjectBox performance.
  public LocalSession(
      int id, @Nullable String userBigTableKey, @Nullable String cloudDataSessionId,
      @Nullable String earbudsConfig, Status status, boolean uploadNeeded, boolean receivedData,
      int eegSamplesUploaded, long eegSamplesDeleted, float eegSampleRate,
      int accelerationsUploaded, long accelerationsDeleted, float accelerationSampleRate,
      int deviceInternalStateUploaded, Instant startTime, @Nullable Instant endTime) {
    super(id);
    this.userBigTableKey = userBigTableKey;
    this.cloudDataSessionId = cloudDataSessionId;
    this.earbudsConfig = earbudsConfig;
    this.status = status;
    this.uploadNeeded = uploadNeeded;
    this.receivedData = receivedData;
    this.eegSamplesUploaded = eegSamplesUploaded;
    this.eegSamplesDeleted = eegSamplesDeleted;
    this.eegSampleRate = eegSampleRate;
    this.accelerationsUploaded = accelerationsUploaded;
    this.accelerationsDeleted = accelerationsDeleted;
    this.accelerationSampleRate = accelerationSampleRate;
    this.deviceInternalStateUploaded = deviceInternalStateUploaded;
    this.startTime = startTime;
    this.endTime = endTime;
  }

  // Needed for ObjectBox performance.
  public LocalSession() {}

  @Nullable
  public String getUserBigTableKey() {
    return userBigTableKey;
  }

  public void setUserBigTableKey(@Nullable String userBigTableKey) {
    this.userBigTableKey = userBigTableKey;
  }

  public @Nullable String getCloudDataSessionId() {
    return cloudDataSessionId;
  }

  public void setCloudDataSessionId(@Nullable String cloudDataSessionId) {
    this.cloudDataSessionId = cloudDataSessionId;
  }

  @Nullable
  public String getEarbudsConfig() {
    return earbudsConfig;
  }

  public void setEarbudsConfig(@Nullable String earbudsConfig) {
    this.earbudsConfig = earbudsConfig;
  }

  public Status getStatus() {
    return status;
  }

  public void setStatus(Status status) {
    this.status = status;
  }

  public int getEegSamplesUploaded() {
    return eegSamplesUploaded;
  }

  public long getEegSamplesDeleted() {
    return eegSamplesDeleted;
  }

  public void setEegSamplesDeleted(long eegSamplesDeleted) {
    this.eegSamplesDeleted = eegSamplesDeleted;
  }

  public boolean isUploadNeeded() {
    return uploadNeeded;
  }

  public void setUploadNeeded(boolean uploadNeeded) {
    this.uploadNeeded = uploadNeeded;
  }

  public boolean isReceivedData() {
    return receivedData;
  }

  public void setReceivedData(boolean receivedData) {
    this.receivedData = receivedData;
  }

  public int getAccelerationsUploaded() {
    return accelerationsUploaded;
  }

  public long getAccelerationsDeleted() {
    return accelerationsDeleted;
  }

  public void setAccelerationsDeleted(long accelerationsDeleted) {
    this.accelerationsDeleted = accelerationsDeleted;
  }

  public void setEegSamplesUploaded(int eegSamplesUploaded) {
    this.eegSamplesUploaded = eegSamplesUploaded;
  }

  public float getEegSampleRate() {
    return eegSampleRate;
  }

  public void setEegSampleRate(float eegSampleRate) {
    this.eegSampleRate = eegSampleRate;
  }

  public void setAccelerationsUploaded(int accelerationsUploaded) {
    this.accelerationsUploaded = accelerationsUploaded;
  }

  public float getAccelerationSampleRate() {
    return accelerationSampleRate;
  }

  public void setAccelerationSampleRate(float accelerationSampleRate) {
    this.accelerationSampleRate = accelerationSampleRate;
  }

  public int getDeviceInternalStateUploaded() {
    return deviceInternalStateUploaded;
  }

  public void setDeviceInternalStateUploaded(int deviceInternalStateUploaded) {
    this.deviceInternalStateUploaded = deviceInternalStateUploaded;
  }

  public Instant getStartTime() {
    return startTime;
  }

  public void setStartTime(Instant startTime) {
    this.startTime = startTime;
  }

  @Nullable
  public Instant getEndTime() {
    return endTime;
  }

  public void setEndTime(@Nullable Instant endTime) {
    this.endTime = endTime;
  }

  public static class StatusConverter implements PropertyConverter<Status, Integer> {
    @Override
    public LocalSession.Status convertToEntityProperty(Integer databaseValue) {
      if (databaseValue == null) {
        return null;
      }
      for (LocalSession.Status status : LocalSession.Status.values()) {
        if (status.id == databaseValue) {
          return status;
        }
      }
      return LocalSession.Status.NOT_STARTED;
    }

    @Override
    public Integer convertToDatabaseValue(LocalSession.Status entityProperty) {
      return entityProperty == null ? null : entityProperty.id;
    }
  }
}
