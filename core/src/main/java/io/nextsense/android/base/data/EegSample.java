package io.nextsense.android.base.data;

import androidx.annotation.Nullable;

import java.time.Instant;
import java.util.Map;
import java.util.Optional;

/**
 * Single EEG multi-channel sampling. Actual channel labels can be determined from the electrodes
 * montage.
 *
 * Either the relative or absolute sampling timestamp need to be provided.
 */
public class EegSample {
  private final Map<Integer, Float> eegSamples;
  private final Instant receptionTimestamp;
  private final Integer relativeSamplingTimestamp;
  private final Instant absoluteSamplingTimestamp;

  public static EegSample create(
      Map<Integer, Float> eegData, Instant receptionTimestamp, @Nullable Integer relativeSamplingTimestamp,
      @Nullable Instant absoluteSamplingTimestamp) {
    if (eegData.isEmpty()) {
      throw new IllegalArgumentException("eegData needs to contain at least 1 element");
    }
    if (relativeSamplingTimestamp == null && absoluteSamplingTimestamp == null) {
      throw new IllegalArgumentException(
          "Either the relative or the absolute timestamp need to be present");
    }
    return new EegSample(eegData, receptionTimestamp, relativeSamplingTimestamp,
        absoluteSamplingTimestamp);
  }

  private EegSample(Map<Integer, Float> eegData, Instant receptionTimestamp,
                    Integer relativeSamplingTimestamp, Instant absoluteSamplingTimestamp) {
    this.eegSamples = eegData;
    this.receptionTimestamp = receptionTimestamp;
    this.relativeSamplingTimestamp = relativeSamplingTimestamp;
    this.absoluteSamplingTimestamp = absoluteSamplingTimestamp;
  }

  public Map<Integer, Float> getEegSamples() {
    return eegSamples;
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

  public boolean isSamplingTimestampAbsolute() {
    return absoluteSamplingTimestamp != null;
  }
}
