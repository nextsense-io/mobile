package io.nextsense.android.base.data;

import androidx.annotation.Nullable;

import java.time.Instant;
import java.util.HashMap;

import io.nextsense.android.base.db.objectbox.Converters;
import io.nextsense.android.base.devices.SampleFlags;
import io.nextsense.android.base.devices.xenon.XenonSampleFlags;
import io.objectbox.annotation.Convert;
import io.objectbox.annotation.Entity;
import io.objectbox.annotation.Index;
import io.objectbox.relation.ToOne;

/**
 * Single EEG multi-channel sampling. Actual channel labels can be determined from the electrodes
 * montage.
 *
 * Either the relative or absolute sampling timestamp need to be provided.
 */
@Entity
public class EegSample extends BaseRecord implements TimestampedDataSample {
  public ToOne<LocalSession> localSession;

  // Key is the channel number, value is the voltage im microVolts.
  @Convert(converter = Converters.SerializableConverter.class, dbType = byte[].class)
  private HashMap<Integer, Float> eegSamples;
  // When the Android application received the packet from the device.
  @Convert(converter = Converters.InstantConverter.class, dbType = Long.class)
  private Instant receptionTimestamp;
  @Nullable
  @Index
  private Integer relativeSamplingTimestamp;
  // When the sample was collected on the device.
  @Convert(converter = Converters.InstantConverter.class, dbType = Long.class)
  @Index
  @Nullable
  private Instant absoluteSamplingTimestamp;
  @Nullable
  private Boolean sync;
  @Nullable
  private Boolean trigOut;
  @Nullable
  private Boolean trigIn;
  @Nullable
  private Boolean zMod;
  @Nullable
  private Boolean marker;
  @Nullable
  private Boolean button;
  @Nullable
  private Boolean hdmiPresent;

  // Needs to be public for ObjectBox performance.
  private EegSample(long localSessionId, HashMap<Integer, Float> eegData,
                    Instant receptionTimestamp, @Nullable Integer relativeSamplingTimestamp,
                    @Nullable Instant absoluteSamplingTimestamp, @Nullable SampleFlags flags) {
    this.localSession = new ToOne<>(this, EegSample_.localSession);
    this.localSession.setTargetId(localSessionId);
    this.eegSamples = eegData;
    this.receptionTimestamp = receptionTimestamp;
    this.relativeSamplingTimestamp = relativeSamplingTimestamp;
    this.absoluteSamplingTimestamp = absoluteSamplingTimestamp;
    setFlags(flags);
  }

  public static EegSample create(
      long localSessionId, HashMap<Integer, Float> eegData, Instant receptionTimestamp,
      @Nullable Integer relativeSamplingTimestamp, @Nullable Instant absoluteSamplingTimestamp,
      @Nullable SampleFlags flags) {
    if (eegData.isEmpty()) {
      throw new IllegalArgumentException("eegData needs to contain at least 1 element");
    }
    if (relativeSamplingTimestamp == null && absoluteSamplingTimestamp == null) {
      throw new IllegalArgumentException(
          "Either the relative or the absolute timestamp need to be present");
    }
    return new EegSample(localSessionId, eegData, receptionTimestamp, relativeSamplingTimestamp,
        absoluteSamplingTimestamp, flags);
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
        absoluteSamplingTimestamp, /*sampleFlags=*/null);
  }

  // Needs to be public for ObjectBox performance.
  public EegSample(long id, long localSessionId, HashMap<Integer, Float> eegData,
                    Instant receptionTimestamp, @Nullable Integer relativeSamplingTimestamp,
                    @Nullable Instant absoluteSamplingTimestamp, @Nullable XenonSampleFlags flags) {
    super(id);
    this.localSession = new ToOne<>(this, EegSample_.localSession);
    this.localSession.setTargetId(localSessionId);
    this.eegSamples = eegData;
    this.receptionTimestamp = receptionTimestamp;
    this.relativeSamplingTimestamp = relativeSamplingTimestamp;
    this.absoluteSamplingTimestamp = absoluteSamplingTimestamp;
    setFlags(flags);
  }

  public EegSample() {}

  private void setFlags(SampleFlags flags) {
    // Can't save to a boolean[], so have to define each property individually.
    if (flags != null) {
      this.sync = flags.isSync();
      this.trigOut = flags.isTrigOut();
      this.trigIn = flags.isTrigIn();
      this.zMod = flags.iszMod();
      this.marker = flags.isMarker();
      this.button = flags.isButton();
      this.hdmiPresent = flags.isHdmiPresent();
    }
  }

  public HashMap<Integer, Float> getEegSamples() {
    return eegSamples;
  }

  @Override
  public Instant getReceptionTimestamp() {
    return receptionTimestamp;
  }

  @Override
  public @Nullable Integer getRelativeSamplingTimestamp() {
    return relativeSamplingTimestamp;
  }

  @Override
  public @Nullable Instant getAbsoluteSamplingTimestamp() {
    return absoluteSamplingTimestamp;
  }

  public boolean isSamplingTimestampAbsolute() {
    return absoluteSamplingTimestamp != null;
  }

  @Nullable
  public Boolean getSync() {
    return sync;
  }

  @Nullable
  public Boolean getTrigOut() {
    return trigOut;
  }

  @Nullable
  public Boolean getTrigIn() {
    return trigIn;
  }

  @Nullable
  public Boolean getZMod() {
    return zMod;
  }

  @Nullable
  public Boolean getMarker() {
    return marker;
  }

  @Nullable
  public Boolean getButton() {
    return button;
  }

  @Nullable
  public Boolean getHdmiPresent() {
    return hdmiPresent;
  }
}
