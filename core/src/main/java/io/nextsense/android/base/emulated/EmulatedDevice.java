package io.nextsense.android.base.emulated;

import androidx.annotation.Nullable;

import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;
import com.google.common.util.concurrent.ListeningExecutorService;
import com.google.common.util.concurrent.MoreExecutors;

import org.greenrobot.eventbus.EventBus;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.Executors;

import io.nextsense.android.base.Device;
import io.nextsense.android.base.DeviceData;
import io.nextsense.android.base.DeviceInfo;
import io.nextsense.android.base.DeviceMode;
import io.nextsense.android.base.DeviceSettings;
import io.nextsense.android.base.DeviceState;
import io.nextsense.android.base.DeviceType;
import io.nextsense.android.base.data.Acceleration;
import io.nextsense.android.base.data.DeviceInternalState;
import io.nextsense.android.base.data.EegSample;
import io.nextsense.android.base.data.LocalSession;
import io.nextsense.android.base.data.LocalSessionManager;
import io.nextsense.android.base.data.Sample;
import io.nextsense.android.base.devices.NextSenseDevice;
import io.nextsense.android.base.devices.xenon.XenonSampleFlags;
import io.nextsense.android.base.utils.RotatingFileLogger;

public class EmulatedDevice extends Device {

  private static final String TAG = EmulatedDevice.class.getSimpleName();

  private LocalSessionManager localSessionManager;
  private DeviceSettings deviceSettings;
  private Timer sendSamplesTimer;
  private DeviceState currentState = DeviceState.DISCONNECTED;
  private DeviceMode currentMode = DeviceMode.IDLE;
  DeviceInternalState deviceInternalState;

  private final ListeningExecutorService executorService =
          MoreExecutors.listeningDecorator(Executors.newCachedThreadPool());

  public void setLocalSessionManager(LocalSessionManager localSessionManager) {
    this.localSessionManager = localSessionManager;
  }

  @Override
  public String getName() {
    return "EMULATED_BLE_DEVICE";
  }

  @Override
  public String getAddress() {
    return "EE:EE:EE:EE:EE:EE";
  }

  @Override
  public DeviceState getState() {
    return currentState;
  }

  @Override
  public DeviceMode getMode() {
    return currentMode;
  }

  public boolean requestDeviceState() {
    RotatingFileLogger.get().logd(TAG, "requestDeviceState");
    if (deviceInternalState == null) {
      initDeviceInternalState();
    }

    EventBus.getDefault().post(deviceInternalState);
    return true;
  }

  private void postEmulatedSamples() {
    Optional<LocalSession> localSessionOptional = localSessionManager.getActiveLocalSession();
    if (!localSessionOptional.isPresent()) {
      RotatingFileLogger.get().logw(TAG, "Received data packet without an active session, cannot record it.");
      return;
    }
    LocalSession localSession = localSessionOptional.get();

    List<Short> accelerationData = Arrays.asList((short)100, (short)200, (short)300);

    HashMap<Integer, Float> eegData = new HashMap<>();
    for (Integer activeChannel : getSettings().getEnabledChannels()) {
      eegData.put(activeChannel, activeChannel.floatValue() * (float)1000.0);
    }
    Instant receptionTimestamp = Instant.now();
    Instant samplingTime = receptionTimestamp.minusMillis(1);
    Acceleration acceleration = Acceleration.create(localSession.id, accelerationData.get(0),
            accelerationData.get(1), accelerationData.get(2), receptionTimestamp,
            null, samplingTime);

    EegSample eegSample = EegSample.create(localSession.id, eegData, receptionTimestamp,
            null, samplingTime, XenonSampleFlags.create((byte)0));
    EventBus.getDefault().post(Sample.create(eegSample, acceleration));
  }

  @Override
  public ListenableFuture<Boolean> startStreaming(
      boolean uploadToCloud, @Nullable String userBigTableKey, @Nullable String dataSessionId,
      @Nullable String earbudsConfig, @Nullable Boolean saveToCsv) {

    RotatingFileLogger.get().logd(TAG, "startStreaming");

    if (localSessionManager != null) {
      localSessionManager.startLocalSession(userBigTableKey, dataSessionId, earbudsConfig,
          uploadToCloud, getSettings().getEegStreamingRate(), getSettings().getImuStreamingRate(),
          Boolean.TRUE.equals(saveToCsv));

      final int fireEachMillis = Math.round(1000 / getSettings().getEegStreamingRate());
      sendSamplesTimer = new Timer();
      sendSamplesTimer.schedule(new TimerTask() {
        @Override
        public void run() {
          postEmulatedSamples();
        }
      }, 0, fireEachMillis);
    }

    currentMode = DeviceMode.STREAMING;

    return Futures.immediateFuture(true);
  }

  @Override
  public ListenableFuture<Boolean> stopStreaming() {
    RotatingFileLogger.get().logd(TAG, "stopStreaming");
    if (sendSamplesTimer != null) {
      sendSamplesTimer.purge();
      sendSamplesTimer.cancel();
      sendSamplesTimer = null;
    }

    if (localSessionManager != null) {
      localSessionManager.stopLocalSession();
    }

    currentMode = DeviceMode.IDLE;

    return Futures.immediateFuture(true);
  }

  @Override
  public ListenableFuture<Boolean> startImpedance(
      DeviceSettings.ImpedanceMode impedanceMode, @Nullable Integer channelNumber,
      @Nullable Integer frequencyDivider) {
    return Futures.immediateFuture(false);
  }

  @Override
  public ListenableFuture<Boolean> stopImpedance() {
    return Futures.immediateFuture(false);
  }

  @Override
  public ListenableFuture<Boolean> setImpedanceConfig(
      DeviceSettings.ImpedanceMode impedanceMode, @Nullable Integer channelNumber,
      @Nullable Integer frequencyDivider) {
    return Futures.immediateFuture(false);
  }

  @Override
  public void addOnDeviceInternalStateChangeListener(
      NextSenseDevice.DeviceInternalStateChangeListener listener) {}

  @Override
  public void removeOnDeviceInternalStateChangeListener(
      NextSenseDevice.DeviceInternalStateChangeListener listener) {}

  @Override
  public ListenableFuture<DeviceState> connect(boolean autoReconnect) {
    RotatingFileLogger.get().logd(TAG, "connect");
    return executorService.submit(() -> {
      currentState = DeviceState.CONNECTING;
      notifyDeviceStateChangeListeners(DeviceState.CONNECTING);
      // Simulate some delay
      Thread.sleep(100);
      currentState = DeviceState.CONNECTED;
      notifyDeviceStateChangeListeners(DeviceState.CONNECTED);
      Thread.sleep(100);
      currentState = DeviceState.READY;
      notifyDeviceStateChangeListeners(DeviceState.READY);
      return DeviceState.READY;
    });
  }

  @Override
  public ListenableFuture<DeviceState> disconnect() {
    RotatingFileLogger.get().logd(TAG, "disconnect");
    return executorService.submit(() -> {
      currentState = DeviceState.DISCONNECTING;
      notifyDeviceStateChangeListeners(DeviceState.DISCONNECTING);
      // Simulate some delay
      Thread.sleep(100);
      currentState = DeviceState.DISCONNECTED;
      notifyDeviceStateChangeListeners(DeviceState.DISCONNECTED);
      return DeviceState.DISCONNECTED;
    });
  }

  @Override
  public DeviceInfo getInfo() {
    return new DeviceInfo(
        DeviceType.XENON,
        "1",
        "EMULATED_1",
        "1",
        "2",
        "3",
        "EMULATED_EARBUDS",

        "1",
        "EMULATED_EARBUDS_1",
        "1",
        "2",
        "3"
    );
  }

  @Override
  public DeviceSettings getSettings() {
    if (deviceSettings == null) {
      // Taken from XenonDevice
      deviceSettings = new DeviceSettings();
      deviceSettings.setEnabledChannels(Arrays.asList(1, 3, 6, 7, 8));
      deviceSettings.setEegSamplingRate(250);
      deviceSettings.setEegStreamingRate(250);
      deviceSettings.setImuSamplingRate(250);
      deviceSettings.setImuStreamingRate(250);
      deviceSettings.setImpedanceMode(DeviceSettings.ImpedanceMode.OFF);
      deviceSettings.setImpedanceDivider(25);
    }
    return deviceSettings;
  }

  @Override
  public ListenableFuture<Boolean> setSettings(DeviceSettings newDeviceSettings) {
    deviceSettings = newDeviceSettings;
    return Futures.immediateFuture(false);
  }

  @Override
  public DeviceData getData() {
    // not used
    return null;
  }

  public void emulateDisconnect() {
    RotatingFileLogger.get().logd(TAG, "emulateDisconnect");
    currentState = DeviceState.DISCONNECTED;
    notifyDeviceStateChangeListeners(DeviceState.DISCONNECTED);
  }

  public void emulateConnect() {
    RotatingFileLogger.get().logd(TAG, "emulateConnect");
    currentState = DeviceState.READY;
    notifyDeviceStateChangeListeners(DeviceState.READY);
  }

  @SuppressWarnings("ConstantConditions")
  public void emulateInternalStateChange(Map<String, Object> params) {
    RotatingFileLogger.get().logd(TAG, "emulateInternalStateChange");
    if (deviceInternalState == null) {
      initDeviceInternalState();
    }

    // TODO(alex): later add those fields batteryLow, internalErrorDetected
    if (params.containsKey(DeviceInternalState.FIELD_U_SD_PRESENT))
      deviceInternalState.setuSdPresent(
              (boolean)params.get(DeviceInternalState.FIELD_U_SD_PRESENT));
    if (params.containsKey(DeviceInternalState.FIELD_HDMI_CABLE_PRESENT))
      deviceInternalState.setHdmiCablePresent(
              (boolean)params.get(DeviceInternalState.FIELD_HDMI_CABLE_PRESENT));

    EventBus.getDefault().post(deviceInternalState);
  }

  private void initDeviceInternalState() {
    Instant timestamp = Instant.now();
    short batteryMilliVolts = 4000;
    int samplesCounter = 0;
    short bleQueueBacklog = 0;
    int lostSamplesCounter = 0;
    short bleRssi = 0;
    ArrayList<Boolean> leadsOffPositive = new ArrayList<>();
    deviceInternalState = DeviceInternalState.create(
            /*localSessionId=*/(long)0,
            timestamp,
            batteryMilliVolts,
            /*busy=*/false,
            /*uSdPresent=*/true,
            /*hdmiCablePresent=*/true,
            /*rtcClockSet=*/true,
            /*captureRunning=*/false,
            /*charging=*/false,
            /*batteryLow=*/false,
            /*uSdLoggingEnabled=*/false,
            /*internalErrorDetected=*/false,
            samplesCounter, bleQueueBacklog, lostSamplesCounter,
            bleRssi, leadsOffPositive);
  }

}
