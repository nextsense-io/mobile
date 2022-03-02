package io.nextsense.android.base.data;

import androidx.annotation.Nullable;

import java.time.Instant;
import java.util.HashMap;

import io.nextsense.android.base.db.objectbox.Converters;
import io.nextsense.android.base.devices.xenon.SampleFlags;
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

  // Key is the channel number, value is the voltage im milliVolts.
  @Convert(converter = Converters.SerializableConverter.class, dbType = byte[].class)
  private HashMap<Integer, Float> eegSamples;
  // When the Android application received the packet from the device.
  @Convert(converter = Converters.InstantConverter.class, dbType = Long.class)
  private Instant receptionTimestamp;
  @Nullable
  private Integer relativeSamplingTimestamp;
  // When the sample was colelcted on the device.
  @Convert(converter = Converters.InstantConverter.class, dbType = Long.class)
  @Nullable
  private Instant absoluteSamplingTimestamp;
  private boolean sync;
  private boolean trigOut;
  private boolean trigIn;
  private boolean zMod;
  private boolean marker;
  private boolean tbd6;
  private boolean tbd7;
  private boolean button;

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
                    @Nullable Instant absoluteSamplingTimestamp, @Nullable SampleFlags flags) {
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
      this.tbd6 = flags.isTbd6();
      this.tbd7 = flags.isTbd7();
      this.button = flags.isButton();
    }
  }

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

  public boolean getSync() {
    return sync;
  }

  public boolean getTrigOut() {
    return trigOut;
  }

  public boolean getTrigIn() {
    return trigIn;
  }

  public boolean getZMod() {
    return zMod;
  }

  public boolean getMarker() {
    return marker;
  }

  public boolean getTbd6() {
    return tbd6;
  }

  public boolean getTbd7() {
    return tbd7;
  }

  public boolean getButton() {
    return button;
  }
}
