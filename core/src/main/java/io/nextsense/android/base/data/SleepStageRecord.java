package io.nextsense.android.base.data;

import androidx.annotation.Nullable;

import java.time.Instant;

import io.nextsense.android.base.db.objectbox.Converters;
import io.objectbox.annotation.Convert;
import io.objectbox.annotation.Entity;
import io.objectbox.relation.ToOne;

// @Entity
public class SleepStageRecord {  // extends BaseRecord {

  public enum SleepStage {
    UNSPECIFIED(0),
    WAKE(1),
    SLEEPING(2);

    private final int value;

    SleepStage(int value) {
      this.value = value;
    }

    public int getValue() {
      return value;
    }

    public static SleepStage fromValue(int value) {
      for (SleepStage state : SleepStage.values()) {
        if (state.value == value) {
          return state;
        }
      }
      return null;
    }
  }

  public ToOne<LocalSession> localSession;

  @Nullable
  private SleepStage sleepStage;
  @Convert(converter = Converters.InstantConverter.class, dbType = Long.class)
  private Instant receptionTimestamp;
  @Nullable
  private Integer relativeSamplingTimestamp;

  public SleepStageRecord() {
    super();
  }

  // Needs to be public for ObjectBox performance.
  public SleepStageRecord(SleepStage sleepStage, Instant receptionTimestamp,
                          Integer relativeSamplingTimestamp) {
    super();
    this.sleepStage = sleepStage;
    this.receptionTimestamp = receptionTimestamp;
    this.relativeSamplingTimestamp = relativeSamplingTimestamp;
  }

  public SleepStage getSleepStage() {
    return sleepStage;
  }

  public Instant getReceptionTimestamp() {
    return receptionTimestamp;
  }

  public Integer getRelativeSamplingTimestamp() {
    return relativeSamplingTimestamp;
  }
}
