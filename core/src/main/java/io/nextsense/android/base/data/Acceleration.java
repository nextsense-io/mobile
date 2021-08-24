package io.nextsense.android.base.data;

import androidx.annotation.Nullable;

import java.time.Instant;

import io.nextsense.android.base.db.objectbox.Converters;
import io.objectbox.annotation.Convert;
import io.objectbox.annotation.Entity;
import io.objectbox.relation.ToOne;

/**
 * IMU Acceleration components.
 *
 * Either the relative or absolute sampling timestamp need to be provided.
 */
@Entity
public class Acceleration extends BaseRecord {
  public ToOne<LocalSession> localSession;

  private final int x;
  private final int y;
  private final int z;
  @Convert(converter = Converters.InstantConverter.class, dbType = Long.class)
  private final Instant receptionTimestamp;
  @Nullable
  private final Integer relativeSamplingTimestamp;
  @Convert(converter = Converters.InstantConverter.class, dbType = Long.class)
  @Nullable
  private final Instant absoluteSamplingTimestamp;

  private Acceleration(long localSessionId, int x, int y, int z, Instant receptionTimestamp,
                       @Nullable Integer relativeSamplingTimestamp,
                       @Nullable Instant absoluteSamplingTimestamp) {
    this.localSession = new ToOne<>(this, Acceleration_.localSession);
    this.localSession.setTargetId(localSessionId);
    this.x = x;
    this.y = y;
    this.z = z;
    this.receptionTimestamp = receptionTimestamp;
    this.relativeSamplingTimestamp = relativeSamplingTimestamp;
    this.absoluteSamplingTimestamp = absoluteSamplingTimestamp;
  }

  public static Acceleration create(
      long localSessionId, int x, int y, int z, Instant receptionTimestamp,
      @Nullable Integer relativeSamplingTimestamp, @Nullable Instant absoluteSamplingTimestamp) {
    if (relativeSamplingTimestamp == null && absoluteSamplingTimestamp == null) {
      throw new IllegalArgumentException(
          "Either the relative or the absolute timestamp need to be present");
    }
    return new Acceleration(localSessionId, x, y, z, receptionTimestamp, relativeSamplingTimestamp,
        absoluteSamplingTimestamp);
  }

  // Needs to be public for ObjectBox performance.
  public Acceleration(long id, long localSessionId, int x, int y, int z, Instant receptionTimestamp,
                      @Nullable Integer relativeSamplingTimestamp,
                      @Nullable Instant absoluteSamplingTimestamp) {
    super(id);
    this.localSession = new ToOne<>(this, Acceleration_.localSession);
    this.localSession.setTargetId(localSessionId);
    this.x = x;
    this.y = y;
    this.z = z;
    this.receptionTimestamp = receptionTimestamp;
    this.relativeSamplingTimestamp = relativeSamplingTimestamp;
    this.absoluteSamplingTimestamp = absoluteSamplingTimestamp;
  }

  public LocalSession getLocalSession() {
    return localSession.getTarget();
  }

  public int getX() {
    return x;
  }

  public int getY() {
    return y;
  }

  public int getZ() {
    return z;
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
}
