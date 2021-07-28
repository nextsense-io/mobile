package io.nextsense.android.base.data;

import androidx.annotation.Nullable;

import java.time.Instant;
import java.util.Optional;

/**
 * IMU Acceleration components.
 *
 * Either the relative or absolute sampling timestamp need to be provided.
 */
public class Acceleration {

  private final int x;
  private final int y;
  private final int z;
  private final Instant receptionTimestamp;
  private final Integer relativeSamplingTimestamp;
  private final Instant absoluteSamplingTimestamp;

  public static Acceleration create(
      int x, int y, int z, Instant receptionTimestamp, @Nullable Integer relativeSamplingTimestamp,
      @Nullable Instant absoluteSamplingTimestamp) {
    if (relativeSamplingTimestamp == null && absoluteSamplingTimestamp == null) {
      throw new IllegalArgumentException(
          "Either the relative or the absolute timestamp need to be present");
    }
    return new Acceleration(x, y, z, receptionTimestamp, relativeSamplingTimestamp,
        absoluteSamplingTimestamp);
  }

  private Acceleration(int x, int y, int z, Instant receptionTimestamp,
                       Integer relativeSamplingTimestamp, Instant absoluteSamplingTimestamp) {
    this.x = x;
    this.y = y;
    this.z = z;
    this.receptionTimestamp = receptionTimestamp;
    this.relativeSamplingTimestamp = relativeSamplingTimestamp;
    this.absoluteSamplingTimestamp = absoluteSamplingTimestamp;
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

  public Optional<Integer> getRelativeSamplingTimestamp() {
    return Optional.ofNullable(relativeSamplingTimestamp);
  }

  public Optional<Instant> getAbsoluteSamplingTimestamp() {
    return Optional.ofNullable(absoluteSamplingTimestamp);
  }
}
