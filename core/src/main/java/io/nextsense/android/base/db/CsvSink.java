package io.nextsense.android.base.db;

import android.content.Context;

import org.greenrobot.eventbus.EventBus;
import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;

import java.util.ArrayList;
import java.util.List;

import io.nextsense.android.base.data.EegSample;
import io.nextsense.android.base.data.LocalSession;
import io.nextsense.android.base.data.Samples;
import io.nextsense.android.base.db.objectbox.ObjectBoxDatabase;
import io.nextsense.android.base.utils.CsvWriter;
import io.nextsense.android.base.utils.RotatingFileLogger;
import io.objectbox.reactive.DataSubscription;

public class CsvSink {

  private static final String TAG = CsvSink.class.getSimpleName();

  private final ObjectBoxDatabase objectBoxDatabase;
  private final CsvWriter csvWriter;
  private DataSubscription uploadedSessionSubscription;
  private Long currentSessionId;

  private CsvSink(Context context, ObjectBoxDatabase objectBoxDatabase) {
    this.objectBoxDatabase = objectBoxDatabase;
    csvWriter = new CsvWriter(context);
  }

  public static CsvSink create(Context context, ObjectBoxDatabase objectBoxDatabase) {
    return new CsvSink(context, objectBoxDatabase);
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
    csvWriter.initCsvFile(filename, earbudsConfig);
    currentSessionId = localSessionId;
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
    if (samples.getEegSamples().size() != samples.getAccelerations().size()) {
      RotatingFileLogger.get().loge(TAG, "Number of EEG samples and accelerations does not match!");
      return;
    }
    for (int i = 0; i < samples.getEegSamples().size(); i++) {
      EegSample eegSample = samples.getEegSamples().get(i);
      List<Float> eegData = new ArrayList<>();
      for (int j = 1; j < 9;++j) {
        eegData.add(eegSample.getEegSamples().getOrDefault(j, 0.0f));
      }
      List<Float> accData = new ArrayList<>();
      accData.add((float)samples.getAccelerations().get(i).getX());
      accData.add((float)samples.getAccelerations().get(i).getY());
      accData.add((float)samples.getAccelerations().get(i).getZ());
      csvWriter.appendData(eegData, accData,
          eegSample.getAbsoluteSamplingTimestamp().toEpochMilli(),
          eegSample.getReceptionTimestamp().toEpochMilli(), /*impedance_flag=*/0,
          boolToInt(eegSample.getSync()), boolToInt(eegSample.getTrigOut()),
          boolToInt(eegSample.getTrigIn()), boolToInt(eegSample.getZMod()),
          boolToInt(eegSample.getMarker()), /*tbd6=*/0, /*tbd7=*/0, boolToInt(eegSample.getButton())
          );
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
}
