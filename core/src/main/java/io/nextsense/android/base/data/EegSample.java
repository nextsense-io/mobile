package io.nextsense.android.base.data;

import androidx.annotation.Nullable;

import java.time.Instant;
import java.util.HashMap;

import io.nextsense.android.base.db.objectbox.Converters;
import io.objectbox.annotation.Convert;
import io.objectbox.annotation.Entity;
import io.objectbox.relation.ToOne;

/**
 * Single EEG multi-channel sampling. Actual channel labels can be determined from the electrodes
 * montage.
 *
 * Either the relative or absolute sampling timestamp need to be provided.
 */
@Entity
public class EegSample extends BaseRecord {
  public ToOne<LocalSession> localSession;

  @Convert(converter = Converters.SerializableConverter.class, dbType = byte[].class)
  private HashMap<Integer, Float> eegSamples;
  @Convert(converter = Converters.InstantConverter.class, dbType = Long.class)
  private Instant receptionTimestamp;
  @Nullable
  private Integer relativeSamplingTimestamp;
  @Convert(converter = Converters.InstantConverter.class, dbType = Long.class)
  @Nullable
  private Instant absoluteSamplingTimestamp;

  // Needs to be public for ObjectBox performance.
  private EegSample(long localSessionId, HashMap<Integer, Float> eegData,
                    Instant receptionTimestamp, @Nullable Integer relativeSamplingTimestamp,
                    @Nullable Instant absoluteSamplingTimestamp) {
    this.localSession = new ToOne<>(this, EegSample_.localSession);
    this.localSession.setTargetId(localSessionId);
    this.eegSamples = eegData;
    this.receptionTimestamp = receptionTimestamp;
    this.relativeSamplingTimestamp = relativeSamplingTimestamp;
    this.absoluteSamplingTimestamp = absoluteSamplingTimestamp;
  }

  public static EegSample create(
      long localSessionId, HashMap<Integer, Float> eegData, Instant receptionTimestamp,
      @Nullable Integer relativeSamplingTimestamp, @Nullable Instant absoluteSamplingTimestamp) {
    if (eegData.isEmpty()) {
      throw new IllegalArgumentException("eegData needs to contain at least 1 element");
    }
    if (relativeSamplingTimestamp == null && absoluteSamplingTimestamp == null) {
      throw new IllegalArgumentException(
          "Either the relative or the absolute timestamp need to be present");
    }
    return new EegSample(localSessionId, eegData, receptionTimestamp, relativeSamplingTimestamp,
        absoluteSamplingTimestamp);
  }

  // Needs to be public for ObjectBox performance.
  public EegSample(long id, long localSessionId, HashMap<Integer, Float> eegData,
                    Instant receptionTimestamp, @Nullable Integer relativeSamplingTimestamp,
                    @Nullable Instant absoluteSamplingTimestamp) {
    super(id);
    this.localSession = new ToOne<>(this, EegSample_.localSession);
    this.localSession.setTargetId(localSessionId);
    this.eegSamples = eegData;
    this.receptionTimestamp = receptionTimestamp;
    this.relativeSamplingTimestamp = relativeSamplingTimestamp;
    this.absoluteSamplingTimestamp = absoluteSamplingTimestamp;
  }

  public EegSample() {}

  public HashMap<Integer, Float> getEegSamples() {
    return eegSamples;
  }

  public Instant getReceptionTimestamp() {
    return receptionTimestamp;
  }

  public @Nullable Integer getRelativeSamplingTimestamp() {
    return relativeSamplingTimestamp;
  }

  public @Nullable Instant getAbsoluteSamplingTimestamp() {
    return absoluteSamplingTimestamp;
  }

  public boolean isSamplingTimestampAbsolute() {
    return absoluteSamplingTimestamp != null;
  }
}
