package io.nextsense.android.base.data;

import androidx.annotation.Nullable;

import java.time.Instant;

interface TimestampedDataSample {

  Instant getReceptionTimestamp();

  @Nullable Integer getRelativeSamplingTimestamp();

  @Nullable Instant getAbsoluteSamplingTimestamp();
}
