package io.nextsense.android.base.data;

import androidx.annotation.Nullable;

import io.objectbox.annotation.Convert;
import io.objectbox.annotation.Entity;
import io.objectbox.converter.PropertyConverter;

/**
 * Local session stored in the local database for sessions that have not been uploaded yet.
 */
@Entity
public class LocalSession extends BaseRecord {

  public enum Status {
    NOT_STARTED(0),
    RECORDING(1),
    FINISHED(2),
    UPLOADED(3);

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
  @Convert(converter = StatusConverter.class, dbType = Integer.class)
  private Status status;
  private boolean uploadNeeded;
  private int eegSamplesUploaded;
  private int accelerationsUploaded;

  private LocalSession(@Nullable String userBigTableKey, @Nullable String cloudDataSessionId,
                       Status status, boolean uploadNeeded, int eegSamplesUploaded,
                       int accelerationsUploaded) {
    super();
    this.cloudDataSessionId = cloudDataSessionId;
    this.userBigTableKey = userBigTableKey;
    this.status = status;
    this.uploadNeeded = uploadNeeded;
    this.eegSamplesUploaded = eegSamplesUploaded;
    this.accelerationsUploaded = accelerationsUploaded;
  }

  public static LocalSession create(
      @Nullable String userBigTableKey, @Nullable String cloudDataSessionId, boolean uploadNeeded) {
    return new LocalSession(cloudDataSessionId, userBigTableKey, Status.RECORDING, uploadNeeded,
        /*recordsUploaded=*/0, /*accelerationsUploaded=*/0);
  }

  // Need to be public for ObjectBox performance.
  public LocalSession(int id, @Nullable String userBigTableKey, @Nullable String cloudDataSessionId,
                      Status status, boolean uploadNeeded, int eegSamplesUploaded,
                      int accelerationsUploaded) {
    super(id);
    this.cloudDataSessionId = cloudDataSessionId;
    this.userBigTableKey = userBigTableKey;
    this.status = status;
    this.uploadNeeded = uploadNeeded;
    this.eegSamplesUploaded = eegSamplesUploaded;
    this.accelerationsUploaded = accelerationsUploaded;
  }

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

  public Status getStatus() {
    return status;
  }

  public void setStatus(Status status) {
    this.status = status;
  }

  public int getEegSamplesUploaded() {
    return eegSamplesUploaded;
  }

  public boolean isUploadNeeded() {
    return uploadNeeded;
  }

  public void setUploadNeeded(boolean uploadNeeded) {
    this.uploadNeeded = uploadNeeded;
  }

  public int getAccelerationsUploaded() {
    return accelerationsUploaded;
  }

  public void setEegSamplesUploaded(int eegSamplesUploaded) {
    this.eegSamplesUploaded = eegSamplesUploaded;
  }

  public void setAccelerationsUploaded(int accelerationsUploaded) {
    this.accelerationsUploaded = accelerationsUploaded;
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
