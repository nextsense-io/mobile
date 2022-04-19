package io.nextsense.android.base.data;

import com.google.gson.annotations.Expose;
import com.google.gson.annotations.JsonAdapter;

import java.time.Instant;
import java.util.ArrayList;

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

  // These field keys must match with ones declared dart side.
  // in DeviceInternalState.dart
  public static final String FIELD_HDMI_CABLE_PRESENT = "hdmiCablePresent";
  public static final String FIELD_U_SD_PRESENT = "uSdPresent";

  // Can be null when there it no currently running session.
  public @Nullable ToOne<LocalSession> localSession;

  @Expose
  @Convert(converter = Converters.InstantConverter.class, dbType = Long.class)  // ObjectBox
  @JsonAdapter(InstantGsonConverter.class)  // Gson
  Instant timestamp;
  @Expose
  int batteryMilliVolts;
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
  int samplesCounter;
  @Expose
  int bleQueueBacklog;
  @Expose
  int lostSamplesCounter;
  @Expose
  int bleRssi;
  @Expose
  @Convert(converter = Converters.SerializableConverter.class, dbType = byte[].class)
  ArrayList<Boolean> leadsOffPositive;

  private DeviceInternalState(
      @Nullable Long localSessionId, Instant timestamp, short batteryMilliVolts, boolean busy,
      boolean uSdPresent, boolean hdmiCablePresent, boolean rtcClockSet, boolean captureRunning,
      boolean charging, boolean batteryLow, boolean uSdLoggingEnabled,
      boolean internalErrorDetected, int samplesCounter, short bleQueueBacklog,
      int lostSamplesCounter, short bleRssi, ArrayList<Boolean> leadsOffPositive) {
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
    this.samplesCounter = samplesCounter;
    this.bleQueueBacklog = bleQueueBacklog;
    this.lostSamplesCounter = lostSamplesCounter;
    this.bleRssi = bleRssi;
    this.leadsOffPositive = leadsOffPositive;
  }

  public static DeviceInternalState create(
      @Nullable Long localSessionId, Instant timestamp, short batteryMilliVolts, boolean busy,
      boolean uSdPresent, boolean hdmiCablePresent, boolean rtcClockSet, boolean captureRunning,
      boolean charging, boolean batteryLow, boolean uSdLoggingEnabled,
      boolean internalErrorDetected, int samplesCounter, short bleQueueBacklog,
      int lostSamplesCounter, short bleRssi, ArrayList<Boolean> leadsOffPositive) {
    return new DeviceInternalState(localSessionId, timestamp, batteryMilliVolts, busy, uSdPresent,
        hdmiCablePresent, rtcClockSet, captureRunning, charging, batteryLow, uSdLoggingEnabled,
        internalErrorDetected, samplesCounter, bleQueueBacklog, lostSamplesCounter, bleRssi,
        leadsOffPositive);
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

  public int getBatteryMilliVolts() {
    return batteryMilliVolts;
  }

  public void setBatteryMilliVolts(int batteryMilliVolts) {
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

  public int getSamplesCounter() {
    return samplesCounter;
  }

  public void setSamplesCounter(int samplesCounter) {
    this.samplesCounter = samplesCounter;
  }

  public int getBleQueueBacklog() {
    return bleQueueBacklog;
  }

  public void setBleQueueBacklog(int bleQueueBacklog) {
    this.bleQueueBacklog = bleQueueBacklog;
  }

  public int getLostSamplesCounter() {
    return lostSamplesCounter;
  }

  public void setLostSamplesCounter(int lostSamplesCounter) {
    this.lostSamplesCounter = lostSamplesCounter;
  }

  public int getBleRssi() {
    return bleRssi;
  }

  public void setBleRssi(int bleRssi) {
    this.bleRssi = bleRssi;
  }

  public ArrayList<Boolean> getLeadsOffPositive() {
    return leadsOffPositive;
  }

  public void setLeadsOffPositive(ArrayList<Boolean> leadsOffPositive) {
    this.leadsOffPositive = leadsOffPositive;
  }
}
