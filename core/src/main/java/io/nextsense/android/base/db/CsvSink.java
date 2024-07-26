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
import io.nextsense.android.base.data.EegSample;
import io.nextsense.android.base.data.LocalSession;
import io.nextsense.android.base.data.Samples;
import io.nextsense.android.base.db.objectbox.ObjectBoxDatabase;
import io.nextsense.android.base.utils.CsvWriter;
import io.nextsense.android.base.utils.RotatingFileLogger;
import io.objectbox.reactive.DataSubscription;

public class CsvSink {

  private static final String TAG = CsvSink.class.getSimpleName();
  private static final Duration RSSI_CHECK_INTERVAL = Duration.ofSeconds(1);

  private final ObjectBoxDatabase objectBoxDatabase;
  private final BleCentralManagerProxy bleCentralManagerProxy;
  private final CsvWriter csvWriter;
  private BlePeripheralCallbackProxy blePeripheralCallbackProxy;
  private BluetoothPeripheral currentPeripheral;
  private DataSubscription uploadedSessionSubscription;
  private Long currentSessionId;
  private int lastRssi = 0;
  private Instant lastRssiCheck = Instant.now();

  private CsvSink(Context context, ObjectBoxDatabase objectBoxDatabase,
                  BleCentralManagerProxy bleCentralManagerProxy) {
    this.objectBoxDatabase = objectBoxDatabase;
    this.bleCentralManagerProxy = bleCentralManagerProxy;
    csvWriter = new CsvWriter(context);
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
    csvWriter.initCsvFile(filename, earbudsConfig, /*haveRssi=*/true);
    currentSessionId = localSessionId;
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
    csvWriter.closeCsvFile();
  }

  @Subscribe(threadMode = ThreadMode.ASYNC)
  public synchronized void onSamples(Samples samples) {
    if (blePeripheralCallbackProxy != null && currentPeripheral != null &&
        lastRssiCheck.plus(RSSI_CHECK_INTERVAL).isBefore(Instant.now())) {
      currentPeripheral.readRemoteRssi();
      lastRssiCheck = Instant.now();
    }
    String sleepStage = "Unspecified";
    if (!samples.getSleepStateRecords().isEmpty()) {
      sleepStage = samples.getSleepStateRecords().get(0).getSleepStage().name();
    }
    for (int i = 0; i < samples.getEegSamples().size(); i++) {
      EegSample eegSample = samples.getEegSamples().get(i);
      List<Float> eegData = new ArrayList<>();
      for (int j = 1; j < 9; ++j) {
        eegData.add(eegSample.getEegSamples().getOrDefault(j, 0.0f));
      }
      List<Float> accData = new ArrayList<>();
      // TODO(eric): This is a temporary fix for the missing accelerometer data.
      accData.add(0.0f);
      accData.add(0.0f);
      accData.add(0.0f);
//      accData.add((float)samples.getAccelerations().get(i).getX());
//      accData.add((float)samples.getAccelerations().get(i).getY());
//      accData.add((float)samples.getAccelerations().get(i).getZ());

      long samplingTimestamp = eegSample.getRelativeSamplingTimestamp() != null
          ? eegSample.getRelativeSamplingTimestamp()
          : eegSample.getAbsoluteSamplingTimestamp().toEpochMilli();
      csvWriter.appendData(eegData, accData,
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
          csvWriter.closeCsvFile();
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
