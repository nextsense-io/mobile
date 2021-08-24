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

  // Session id assigned in the cloud database. Can be null if the session is local only.
  @Nullable
  private Integer cloudSessionId;
  @Convert(converter = StatusConverter.class, dbType = Integer.class)
  private Status status;
  private boolean uploadNeeded;
  private int eegSamplesUploaded;
  private int accelerationsUploaded;

  private LocalSession(@Nullable Integer cloudSessionId, Status status, boolean uploadNeeded,
                       int eegSamplesUploaded, int accelerationsUploaded) {
    super();
    this.cloudSessionId = cloudSessionId;
    this.status = status;
    this.uploadNeeded = uploadNeeded;
    this.eegSamplesUploaded = eegSamplesUploaded;
    this.accelerationsUploaded = accelerationsUploaded;
  }

  public static LocalSession create(@Nullable Integer cloudSessionId, boolean uploadNeeded) {
    return new LocalSession(cloudSessionId, Status.RECORDING, uploadNeeded, /*recordsUploaded=*/0,
        /*accelerationsUploaded=*/0);
  }

  // Need to be public for ObjectBox performance.
  public LocalSession(int id, @Nullable Integer cloudSessionId, Status status, boolean uploadNeeded,
                      int eegSamplesUploaded, int accelerationsUploaded) {
    super(id);
    this.cloudSessionId = cloudSessionId;
    this.status = status;
    this.uploadNeeded = uploadNeeded;
    this.eegSamplesUploaded = eegSamplesUploaded;
    this.accelerationsUploaded = accelerationsUploaded;
  }

  public @Nullable Integer getCloudSessionId() {
    return cloudSessionId;
  }

  public void setCloudSessionId(@Nullable Integer cloudSessionId) {
    this.cloudSessionId = cloudSessionId;
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
