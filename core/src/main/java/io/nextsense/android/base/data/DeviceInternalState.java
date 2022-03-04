package io.nextsense.android.base.data;

import com.google.gson.annotations.Expose;
import com.google.gson.annotations.JsonAdapter;

import java.time.Instant;

import javax.annotation.Nullable;

import io.nextsense.android.base.db.objectbox.Converters;
import io.objectbox.annotation.Convert;
import io.objectbox.annotation.Entity;
import io.objectbox.relation.ToOne;

/**
 * Local session stored in the local database for sessions that have not been uploaded yet.
 */
@Entity
public class DeviceInternalState extends BaseRecord {

  // Can be null when there it no currently running session.
  public @Nullable ToOne<LocalSession> localSession;

  @Expose
  @Convert(converter = Converters.InstantConverter.class, dbType = Long.class)  // ObjectBox
  @JsonAdapter(InstantGsonConverter.class)  // Gson
  Instant timestamp;
  @Expose
  short batteryMilliVolts;
  @Expose
  boolean busy;
  @Expose
  boolean uSdPresent;
  @Expose
  boolean hdmiCablePresent;
  @Expose
  boolean rtcClockSet;
  @Expose
  boolean captureRunning;
  @Expose
  boolean charging;
  @Expose
  boolean batteryLow;
  @Expose
  boolean uSdLoggingEnabled;
  @Expose
  boolean internalErrorDetected;
  @Expose
  short bleQueueBacklog;
  @Expose
  int lostSamplesCounter;
  @Expose
  short bleRssi;

  private DeviceInternalState(
      @Nullable Long localSessionId, Instant timestamp, short batteryMilliVolts, boolean busy,
      boolean uSdPresent, boolean hdmiCablePresent, boolean rtcClockSet, boolean captureRunning,
      boolean charging, boolean batteryLow, boolean uSdLoggingEnabled,
      boolean internalErrorDetected, short bleQueueBacklog, int lostSamplesCounter, short bleRssi) {
    super();
    this.localSession = new ToOne<>(this, DeviceInternalState_.localSession);
    if (localSessionId != null) {
      this.localSession.setTargetId(localSessionId);
    }
    this.timestamp = timestamp;
    this.batteryMilliVolts = batteryMilliVolts;
    this.busy = busy;
    this.uSdPresent = uSdPresent;
    this.hdmiCablePresent = hdmiCablePresent;
    this.rtcClockSet = rtcClockSet;
    this.captureRunning = captureRunning;
    this.charging = charging;
    this.batteryLow = batteryLow;
    this.uSdLoggingEnabled = uSdLoggingEnabled;
    this.internalErrorDetected = internalErrorDetected;
    this.bleQueueBacklog = bleQueueBacklog;
    this.lostSamplesCounter = lostSamplesCounter;
    this.bleRssi = bleRssi;
  }

  public static DeviceInternalState create(
      @Nullable Long localSessionId, Instant timestamp, short batteryMilliVolts, boolean busy,
      boolean uSdPresent, boolean hdmiCablePresent, boolean rtcClockSet, boolean captureRunning,
      boolean charging, boolean batteryLow, boolean uSdLoggingEnabled,
      boolean internalErrorDetected, short bleQueueBacklog, int lostSamplesCounter, short bleRssi) {
    return new DeviceInternalState(localSessionId, timestamp, batteryMilliVolts, busy, uSdPresent,
        hdmiCablePresent, rtcClockSet, captureRunning, charging, batteryLow, uSdLoggingEnabled,
        internalErrorDetected, bleQueueBacklog, lostSamplesCounter, bleRssi);
  }

  public DeviceInternalState() {
    this.localSession = new ToOne<>(this, DeviceInternalState_.localSession);
  }

  // Need to be public for ObjectBox performance.
  public DeviceInternalState(
      long id, @Nullable Long localSessionId, Instant timestamp, short batteryMilliVolts,
      boolean busy, boolean uSdPresent, boolean hdmiCablePresent, boolean rtcClockSet,
      boolean captureRunning, boolean charging, boolean batteryLow, boolean uSdLoggingEnabled,
      boolean internalErrorDetected, short bleQueueBacklog, int lostSamplesCounter, short bleRssi) {
    super(id);
    this.localSession = new ToOne<>(this, EegSample_.localSession);
    if (localSessionId != null) {
      this.localSession.setTargetId(localSessionId);
    }
    this.timestamp = timestamp;
    this.batteryMilliVolts = batteryMilliVolts;
    this.busy = busy;
    this.uSdPresent = uSdPresent;
    this.hdmiCablePresent = hdmiCablePresent;
    this.rtcClockSet = rtcClockSet;
    this.captureRunning = captureRunning;
    this.charging = charging;
    this.batteryLow = batteryLow;
    this.uSdLoggingEnabled = uSdLoggingEnabled;
    this.internalErrorDetected = internalErrorDetected;
    this.bleQueueBacklog = bleQueueBacklog;
    this.lostSamplesCounter = lostSamplesCounter;
    this.bleRssi = bleRssi;
  }

  public Instant getTimestamp() {
    return timestamp;
  }

  public void setTimestamp(Instant timestamp) {
    this.timestamp = timestamp;
  }

  public short getBatteryMilliVolts() {
    return batteryMilliVolts;
  }

  public void setBatteryMilliVolts(short batteryMilliVolts) {
    this.batteryMilliVolts = batteryMilliVolts;
  }

  public boolean isBusy() {
    return busy;
  }

  public void setBusy(boolean busy) {
    this.busy = busy;
  }

  public boolean isuSdPresent() {
    return uSdPresent;
  }

  public void setuSdPresent(boolean uSdPresent) {
    this.uSdPresent = uSdPresent;
  }

  public boolean isHdmiCablePresent() {
    return hdmiCablePresent;
  }

  public void setHdmiCablePresent(boolean hdmiCablePresent) {
    this.hdmiCablePresent = hdmiCablePresent;
  }

  public boolean isRtcClockSet() {
    return rtcClockSet;
  }

  public void setRtcClockSet(boolean rtcClockSet) {
    this.rtcClockSet = rtcClockSet;
  }

  public boolean isCaptureRunning() {
    return captureRunning;
  }

  public void setCaptureRunning(boolean captureRunning) {
    this.captureRunning = captureRunning;
  }

  public boolean isCharging() {
    return charging;
  }

  public void setCharging(boolean charging) {
    this.charging = charging;
  }

  public boolean isBatteryLow() {
    return batteryLow;
  }

  public void setBatteryLow(boolean batteryLow) {
    this.batteryLow = batteryLow;
  }

  public boolean isuSdLoggingEnabled() {
    return uSdLoggingEnabled;
  }

  public void setuSdLoggingEnabled(boolean uSdLoggingEnabled) {
    this.uSdLoggingEnabled = uSdLoggingEnabled;
  }

  public boolean isInternalErrorDetected() {
    return internalErrorDetected;
  }

  public void setInternalErrorDetected(boolean internalErrorDetected) {
    this.internalErrorDetected = internalErrorDetected;
  }

  public short getBleQueueBacklog() {
    return bleQueueBacklog;
  }

  public void setBleQueueBacklog(short bleQueueBacklog) {
    this.bleQueueBacklog = bleQueueBacklog;
  }

  public int getLostSamplesCounter() {
    return lostSamplesCounter;
  }

  public void setLostSamplesCounter(int lostSamplesCounter) {
    this.lostSamplesCounter = lostSamplesCounter;
  }

  public short getBleRssi() {
    return bleRssi;
  }

  public void setBleRssi(short bleRssi) {
    this.bleRssi = bleRssi;
  }
}
