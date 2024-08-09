package io.nextsense.android.base.db;

import android.content.Context;

import com.welie.blessed.BluetoothPeripheral;
import com.welie.blessed.BluetoothPeripheralCallback;
import com.welie.blessed.GattStatus;

import org.greenrobot.eventbus.EventBus;
import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;
import org.jetbrains.annotations.NotNull;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

import io.nextsense.android.base.communication.ble.BleCentralManagerProxy;
import io.nextsense.android.base.communication.ble.BlePeripheralCallbackProxy;
import io.nextsense.android.base.data.DeviceLocation;
import io.nextsense.android.base.data.EegSample;
import io.nextsense.android.base.data.LocalSession;
import io.nextsense.android.base.data.Samples;
import io.nextsense.android.base.db.objectbox.ObjectBoxDatabase;
import io.nextsense.android.base.utils.CsvWriter;
import io.nextsense.android.base.utils.RotatingFileLogger;
import io.objectbox.reactive.DataSubscription;

public class CsvSink {

  private static final String TAG = CsvSink.class.getSimpleName();
  private static final Duration RSSI_CHECK_INTERVAL = Duration.ofSeconds(5);

  private final ObjectBoxDatabase objectBoxDatabase;
  private final BleCentralManagerProxy bleCentralManagerProxy;
  private final CsvWriter leftCsvWriter;
  private final CsvWriter rightCsvWriter;
  private BlePeripheralCallbackProxy blePeripheralCallbackProxy;
  private BluetoothPeripheral currentPeripheral;
  private DataSubscription uploadedSessionSubscription;
  private Long currentSessionId;
  private int lastRssi = 0;
  private Instant lastRssiCheck = Instant.now();
  private float eegSamplingRate;
  private float imuSamplingRate;

  private CsvSink(Context context, ObjectBoxDatabase objectBoxDatabase,
                  BleCentralManagerProxy bleCentralManagerProxy) {
    this.objectBoxDatabase = objectBoxDatabase;
    this.bleCentralManagerProxy = bleCentralManagerProxy;
    leftCsvWriter = new CsvWriter(context);
    rightCsvWriter = new CsvWriter(context);
  }

  public static CsvSink create(Context context, ObjectBoxDatabase objectBoxDatabase,
                               BleCentralManagerProxy bleCentralManagerProxy) {
    return new CsvSink(context, objectBoxDatabase, bleCentralManagerProxy);
  }

  public void setBluetoothPeripheralProxy(BlePeripheralCallbackProxy proxy) {
    blePeripheralCallbackProxy = proxy;
    blePeripheralCallbackProxy.addPeripheralCallbackListener(bleCallbackListener);
  }

  public void startListening() {
    if (EventBus.getDefault().isRegistered(this)) {
      RotatingFileLogger.get().logw(TAG, "Already registered to EventBus!");
      return;
    }
    EventBus.getDefault().register(this);
    RotatingFileLogger.get().logi(TAG, "Started listening to EventBus.");
  }

  public void stopListening() {
    EventBus.getDefault().unregister(this);
    RotatingFileLogger.get().logi(TAG, "Stopped listening to EventBus.");
    if (uploadedSessionSubscription != null) {
      uploadedSessionSubscription.cancel();
    }
  }

  public void openCsv(String filename, String earbudsConfig, long localSessionId) {
    leftCsvWriter.initCsvFile(filename + "_left", earbudsConfig, /*haveRssi=*/true);
    rightCsvWriter.initCsvFile(filename + "_right", earbudsConfig, /*haveRssi=*/true);
    currentSessionId = localSessionId;
    LocalSession localSession = objectBoxDatabase.getLocalSession(localSessionId);
    eegSamplingRate = localSession.getEegSampleRate();
    imuSamplingRate = localSession.getAccelerationSampleRate();
    if (bleCentralManagerProxy.getCentralManager().getConnectedPeripherals().isEmpty()) {
      RotatingFileLogger.get().logw(TAG, "No connected peripherals!");
      return;
    }
    currentPeripheral = bleCentralManagerProxy.getCentralManager().getConnectedPeripherals().get(0);
  }

  public void closeCsv(boolean checkForUploadedSession) {
    if (checkForUploadedSession && currentSessionId != null) {
      LocalSession completedSession =
          objectBoxDatabase.getUploadedLocalSession(currentSessionId).findFirst();
      if (completedSession == null) {
        uploadedSessionSubscription = subscribeToUploadedSession(currentSessionId);
        return;
      }
    }
    if (uploadedSessionSubscription != null) {
      uploadedSessionSubscription.cancel();
      uploadedSessionSubscription = null;
    }
    leftCsvWriter.closeCsvFile();
    rightCsvWriter.closeCsvFile();
  }

  @Subscribe(threadMode = ThreadMode.ASYNC)
  public synchronized void onSamples(Samples samples) {
    if (blePeripheralCallbackProxy != null && currentPeripheral != null &&
        lastRssiCheck.plus(RSSI_CHECK_INTERVAL).isBefore(Instant.now())) {
      currentPeripheral.readRemoteRssi();
      lastRssiCheck = Instant.now();
    }
    String sleepStage = "Unspecified";
    if (samples.getEegSamples().isEmpty()) {
      RotatingFileLogger.get().logw(TAG, "No EEG samples!");
      return;
    }

    if (!samples.getSleepStateRecords().isEmpty()) {
      sleepStage = samples.getSleepStateRecords().get(0).getSleepStage().name();
    }

    List<List<Float>> leftImuSamples = new ArrayList<>();
    List<List<Float>> rightImuSamples = new ArrayList<>();
    boolean hasAngularSpeeds = !samples.getAngularSpeeds().isEmpty();
    if (hasAngularSpeeds &&
        samples.getAngularSpeeds().size() != samples.getAccelerations().size()) {
      RotatingFileLogger.get().logw(TAG,
          "Number of accelerometer samples does not match angular speed samples.");
      return;
    }
    for (int i = 0; i < samples.getAccelerations().size(); i++) {
      List<Float> leftImuData = new ArrayList<>();
      List<Float> rightImuData = new ArrayList<>();
      if (samples.getAccelerations().get(i).getLeftX() != null) {
        leftImuData.add((float) samples.getAccelerations().get(i).getLeftX());
        leftImuData.add((float) samples.getAccelerations().get(i).getLeftY());
        leftImuData.add((float) samples.getAccelerations().get(i).getLeftZ());
      }
      if (samples.getAccelerations().get(i).getRightX() != null) {
        rightImuData.add((float) samples.getAccelerations().get(i).getRightX());
        rightImuData.add((float) samples.getAccelerations().get(i).getRightY());
        rightImuData.add((float) samples.getAccelerations().get(i).getRightZ());
      }
      if (hasAngularSpeeds) {
        if (samples.getAngularSpeeds().get(i).getLeftX() != null) {
          leftImuData.add((float) samples.getAngularSpeeds().get(i).getLeftX());
          leftImuData.add((float) samples.getAngularSpeeds().get(i).getLeftY());
          leftImuData.add((float) samples.getAngularSpeeds().get(i).getLeftZ());
        }
        if (samples.getAngularSpeeds().get(i).getRightX() != null) {
          rightImuData.add((float) samples.getAngularSpeeds().get(i).getRightX());
          rightImuData.add((float) samples.getAngularSpeeds().get(i).getRightY());
          rightImuData.add((float) samples.getAngularSpeeds().get(i).getRightZ());
        }
      }
      leftImuSamples.add(leftImuData);
      rightImuSamples.add(rightImuData);
    }

    float imuToEegRatio = eegSamplingRate / imuSamplingRate;

    DeviceLocation deviceLocation = samples.getEegSamples().get(0).getEegSamples().get(1) != null
        ? DeviceLocation.LEFT_EARBUD
        : DeviceLocation.RIGHT_EARBUD;
    for (int i = 0; i < samples.getEegSamples().size(); i++) {
      EegSample eegSample = samples.getEegSamples().get(i);
      List<Float> eegData = new ArrayList<>();
      for (int j = 1; j < 9; ++j) {
        eegData.add(eegSample.getEegSamples().getOrDefault(j, 0.0f));
      }
      List<Float> leftImuData = new ArrayList<>();
      List<Float> rightImuData = new ArrayList<>();
      if (!leftImuSamples.isEmpty() && i % imuToEegRatio == 0 &&
          leftImuSamples.size() > i / imuToEegRatio) {
        leftImuData = leftImuSamples.get((int) (i / imuToEegRatio));
      }
      if (leftImuData.isEmpty()) {
        leftImuData.add(0.0f);
        leftImuData.add(0.0f);
        leftImuData.add(0.0f);
        leftImuData.add(0.0f);
        leftImuData.add(0.0f);
        leftImuData.add(0.0f);
      }
      if (!rightImuSamples.isEmpty() && i % imuToEegRatio == 0 &&
          rightImuSamples.size() > i / imuToEegRatio) {
        rightImuData = rightImuSamples.get((int) (i / imuToEegRatio));
      }
      if (rightImuData.isEmpty()) {
        rightImuData.add(0.0f);
        rightImuData.add(0.0f);
        rightImuData.add(0.0f);
        rightImuData.add(0.0f);
        rightImuData.add(0.0f);
        rightImuData.add(0.0f);
      }

      long samplingTimestamp = eegSample.getRelativeSamplingTimestamp() != null
          ? eegSample.getRelativeSamplingTimestamp()
          : eegSample.getAbsoluteSamplingTimestamp().toEpochMilli();
      CsvWriter locationCsvWriter = deviceLocation == DeviceLocation.LEFT_EARBUD
          ? leftCsvWriter
          : rightCsvWriter;
      locationCsvWriter.appendData(eegData, leftImuData, rightImuData,
          samplingTimestamp,
          eegSample.getReceptionTimestamp().toEpochMilli(), /*impedance_flag=*/0,
          boolToInt(Boolean.TRUE.equals(eegSample.getSync())),
          boolToInt(Boolean.TRUE.equals(eegSample.getTrigOut())),
          boolToInt(Boolean.TRUE.equals(eegSample.getTrigIn())),
          boolToInt(Boolean.TRUE.equals(eegSample.getZMod())),
          boolToInt(Boolean.TRUE.equals(eegSample.getMarker())), /*tbd6=*/0, /*tbd7=*/0,
          boolToInt(Boolean.TRUE.equals(eegSample.getButton())), lastRssi, sleepStage);
    }
  }

  private DataSubscription subscribeToUploadedSession(long localSessionId) {
    return objectBoxDatabase.getUploadedLocalSession(localSessionId).subscribe()
        .observer(completedSessions -> {
          LocalSession uploadedSession =
              objectBoxDatabase.getUploadedLocalSession(localSessionId).findFirst();
          if (uploadedSession == null) {
            RotatingFileLogger.get().logd(TAG, "No uploaded session, not closing CSV file.");
            return;
          }
          RotatingFileLogger.get().logd(TAG, "uploaded session, closing csv file.");
          leftCsvWriter.closeCsvFile();
          rightCsvWriter.closeCsvFile();
        });
  }

  private int boolToInt(boolean b) {
    return b ? 1 : 0;
  }

  private final BluetoothPeripheralCallback bleCallbackListener = new BluetoothPeripheralCallback() {
    @Override
    public void onReadRemoteRssi(@NotNull BluetoothPeripheral peripheral, int rssi,
                                 @NotNull GattStatus status) {
      lastRssi = rssi;
    }
  };
}
