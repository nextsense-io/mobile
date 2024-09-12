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
    FINISHED(2),  // Session is finished, new samples should not be acquired anymore, but some
    // might still be left on the device to stream.
    ALL_DATA_RECEIVED(5),  // All data received from the device.
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
  private long firstRelativeTimestamp;
  private int eegSamplesUploaded;
  private long uploadedUntilRelative;
  @Convert(converter = Converters.InstantConverter.class, dbType = Long.class)
  private Instant uploadedUntil;
  private long eegSamplesDeleted;
  private long deletedUntilRelative;
  @Convert(converter = Converters.InstantConverter.class, dbType = Long.class)
  private Instant deletedUntil;
  private float eegSampleRate;
  private int accelerationsUploaded;
  private int accelerationsUploadedUntilRelative;
  @Convert(converter = Converters.InstantConverter.class, dbType = Long.class)
  private Instant accelerationsUploadedUntil;
  private long accelerationsDeleted;
  private long accelerationsDeletedUntilRelative;
  @Convert(converter = Converters.InstantConverter.class, dbType = Long.class)
  private Instant accelerationsDeletedUntil;
  private float accelerationSampleRate;
  private int deviceInternalStateUploaded;
  private int deviceInternalStateUploadedUntil;
  @Convert(converter = Converters.InstantConverter.class, dbType = Long.class)
  private Instant startTime;
  @Nullable
  @Convert(converter = Converters.InstantConverter.class, dbType = Long.class)
  private Instant firstDataTime;
  @Nullable
  @Convert(converter = Converters.InstantConverter.class, dbType = Long.class)
  private Instant endTime;

  private LocalSession(@Nullable String userBigTableKey, @Nullable String cloudDataSessionId,
                       @Nullable String earbudsConfig, Status status, boolean uploadNeeded,
                       boolean receivedData, long firstRelativeTimestamp, int eegSamplesUploaded, long uploadedUntilRelative,
                       @Nullable Instant uploadedUntil, long eegSamplesDeleted, long deletedUntilRelative,
                       @Nullable Instant deletedUntil, float eegSampleRate, int accelerationsUploaded,
                       int accelerationsUploadedUntilRelative, @Nullable Instant accelerationsUploadedUntil, long accelerationsDeleted,
                       long accelerationsDeletedUntilRelative, @Nullable Instant accelerationsDeletedUntil,
                       float accelerationSampleRate, int deviceInternalStateUploaded,
                       int deviceInternalStateUploadedUntil, Instant startTime, @Nullable Instant endTime) {
    super();
    this.userBigTableKey = userBigTableKey;
    this.cloudDataSessionId = cloudDataSessionId;
    this.earbudsConfig = earbudsConfig;
    this.status = status;
    this.uploadNeeded = uploadNeeded;
    this.receivedData = receivedData;
    this.firstRelativeTimestamp = firstRelativeTimestamp;
    this.eegSamplesUploaded = eegSamplesUploaded;
    this.uploadedUntilRelative = uploadedUntilRelative;
    this.uploadedUntil = uploadedUntil;
    this.eegSamplesDeleted = eegSamplesDeleted;
    this.deletedUntilRelative = deletedUntilRelative;
    this.deletedUntil = deletedUntil;
    this.eegSampleRate = eegSampleRate;
    this.accelerationsUploaded = accelerationsUploaded;
    this.accelerationsUploadedUntilRelative = accelerationsUploadedUntilRelative;
    this.accelerationsUploadedUntil = accelerationsUploadedUntil;
    this.accelerationsDeleted = accelerationsDeleted;
    this.accelerationsDeletedUntilRelative = accelerationsDeletedUntilRelative;
    this.accelerationsDeletedUntil = accelerationsDeletedUntil;
    this.accelerationSampleRate = accelerationSampleRate;
    this.deviceInternalStateUploaded = deviceInternalStateUploaded;
    this.deviceInternalStateUploadedUntil = deviceInternalStateUploadedUntil;
    this.startTime = startTime;
    this.endTime = endTime;
  }

  public static LocalSession create(
      @Nullable String userBigTableKey, @Nullable String cloudDataSessionId,
      @Nullable String earbudsConfig, boolean uploadNeeded, boolean receivedData,
      float eegSampleRate, float accelerationSampleRate, Instant startTime) {
    return new LocalSession(userBigTableKey, cloudDataSessionId, earbudsConfig, Status.RECORDING,
        uploadNeeded, receivedData, /*firstRelativeTimestamp=*/ 0L, /*recordsUploaded=*/0, /*eegSamplesUploadedUntilRelative=*/0L, startTime,
        /*eegSamplesDeleted=*/0L, /*eegSamplesDeletedUntilRelative=*/0L, startTime, eegSampleRate,
        /*accelerationsUploaded=*/0, /*accelerationsUploadedUntilRelative=*/0, startTime,
        /*accelerationsDeleted=*/0L, /*accelerationsDeletedUntilRelative=*/0L, startTime, accelerationSampleRate,
        /*deviceInternalStateUploaded=*/0, /*deviceInternalStateUploadedUntil=*/0, startTime, /*endTime=*/null);
  }

  // Need to be public for ObjectBox performance.
  public LocalSession(
      int id, @Nullable String userBigTableKey, @Nullable String cloudDataSessionId,
      @Nullable String earbudsConfig, Status status, boolean uploadNeeded, boolean receivedData,
      long firstRelativeTimestamp,
      int eegSamplesUploaded, long uploadedUntilRelative, @Nullable Instant uploadedUntil,
      long eegSamplesDeleted, long deletedUntilRelative, @Nullable Instant deletedUntil,
      float eegSampleRate, int accelerationsUploaded, int accelerationsUploadedUntilRelative,
      @Nullable Instant accelerationsUploadedUntil, long accelerationsDeleted, long accelerationsDeletedUntilRelative,
      @Nullable Instant accelerationsDeletedUntil, float accelerationSampleRate,
      int deviceInternalStateUploaded, int deviceInternalStateUploadedUntil, Instant startTime,
      @Nullable Instant endTime) {
    super(id);
    this.userBigTableKey = userBigTableKey;
    this.cloudDataSessionId = cloudDataSessionId;
    this.earbudsConfig = earbudsConfig;
    this.status = status;
    this.uploadNeeded = uploadNeeded;
    this.receivedData = receivedData;
    this.firstRelativeTimestamp = firstRelativeTimestamp;
    this.eegSamplesUploaded = eegSamplesUploaded;
    this.uploadedUntilRelative = uploadedUntilRelative;
    this.uploadedUntil = uploadedUntil;
    this.eegSamplesDeleted = eegSamplesDeleted;
    this.deletedUntilRelative = deletedUntilRelative;
    this.deletedUntil = deletedUntil;
    this.eegSampleRate = eegSampleRate;
    this.accelerationsUploaded = accelerationsUploaded;
    this.accelerationsUploadedUntilRelative = accelerationsUploadedUntilRelative;
    this.accelerationsUploadedUntil = accelerationsUploadedUntil;
    this.accelerationsDeleted = accelerationsDeleted;
    this.accelerationsDeletedUntilRelative = accelerationsDeletedUntilRelative;
    this.accelerationsDeletedUntil = accelerationsDeletedUntil;
    this.accelerationSampleRate = accelerationSampleRate;
    this.deviceInternalStateUploaded = deviceInternalStateUploaded;
    this.deviceInternalStateUploadedUntil = deviceInternalStateUploadedUntil;
    this.startTime = startTime;
    this.endTime = endTime;
  }

  // Needed for ObjectBox performance.
  public LocalSession() {
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

  @Nullable
  public String getUserBigTableKey() {
    return userBigTableKey;
  }

  public long getFirstRelativeTimestamp() {
    return firstRelativeTimestamp;
  }

  public void setFirstRelativeTimestamp(long firstRelativeTimestamp) {
    this.firstRelativeTimestamp = firstRelativeTimestamp;
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

  public void setEegSamplesUploaded(int eegSamplesUploaded) {
    this.eegSamplesUploaded = eegSamplesUploaded;
  }

  public long getUploadedUntilRelative() {
    return uploadedUntilRelative;
  }

  public void setUploadedUntilRelative(long uploadedUntilRelative) {
    this.uploadedUntilRelative = uploadedUntilRelative;
  }

  @Nullable
  public Instant getUploadedUntil() {
    return uploadedUntil;
  }

  public void setUploadedUntil(@Nullable Instant uploadedUntil) {
    this.uploadedUntil = uploadedUntil;
  }

  public long getEegSamplesDeleted() {
    return eegSamplesDeleted;
  }

  public void setEegSamplesDeleted(long eegSamplesDeleted) {
    this.eegSamplesDeleted = eegSamplesDeleted;
  }

  public long getDeletedUntilRelative() {
    return deletedUntilRelative;
  }

  public void setDeletedUntilRelative(long deletedUntilRelative) {
    this.deletedUntilRelative = deletedUntilRelative;
  }

  @Nullable
  public Instant getDeletedUntil() {
    return deletedUntil;
  }

  public void setDeletedUntil(@Nullable Instant deletedUntil) {
    this.deletedUntil = deletedUntil;
  }

  public float getEegSampleRate() {
    return eegSampleRate;
  }

  public void setEegSampleRate(float eegSampleRate) {
    this.eegSampleRate = eegSampleRate;
  }

  public int getAccelerationsUploaded() {
    return accelerationsUploaded;
  }

  public void setAccelerationsUploaded(int accelerationsUploaded) {
    this.accelerationsUploaded = accelerationsUploaded;
  }

  public int getAccelerationsUploadedUntilRelative() {
    return accelerationsUploadedUntilRelative;
  }

  public void setAccelerationsUploadedUntilRelative(int accelerationsUploadedUntilRelative) {
    this.accelerationsUploadedUntilRelative = accelerationsUploadedUntilRelative;
  }

  @Nullable
  public Instant getAccelerationsUploadedUntil() {
    return accelerationsUploadedUntil;
  }

  public void setAccelerationsUploadedUntil(@Nullable Instant accelerationsUploadedUntil) {
    this.accelerationsUploadedUntil = accelerationsUploadedUntil;
  }

  public long getAccelerationsDeleted() {
    return accelerationsDeleted;
  }

  public void setAccelerationsDeleted(long accelerationsDeleted) {
    this.accelerationsDeleted = accelerationsDeleted;
  }

  public long getAccelerationsDeletedUntilRelative() {
    return accelerationsDeletedUntilRelative;
  }

  public void setAccelerationsDeletedUntilRelative(long accelerationsDeletedUntilRelative) {
    this.accelerationsDeletedUntilRelative = accelerationsDeletedUntilRelative;
  }

  @Nullable
  public Instant getAccelerationsDeletedUntil() {
    return accelerationsDeletedUntil;
  }

  public void setAccelerationsDeletedUntil(@Nullable Instant accelerationsDeletedUntil) {
    this.accelerationsDeletedUntil = accelerationsDeletedUntil;
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

  public int getDeviceInternalStateUploadedUntil() {
    return deviceInternalStateUploadedUntil;
  }

  public void setDeviceInternalStateUploadedUntil(int deviceInternalStateUploadedUntil) {
    this.deviceInternalStateUploadedUntil = deviceInternalStateUploadedUntil;
  }

  public Instant getFirstDataTime() {
    return firstDataTime;
  }

  public void setFirstDataTime(Instant firstDataTime) {
    this.firstDataTime = firstDataTime;
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
