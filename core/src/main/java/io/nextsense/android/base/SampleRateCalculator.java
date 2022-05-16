package io.nextsense.android.base;

import android.util.Log;

import org.greenrobot.eventbus.EventBus;
import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;

import java.text.DecimalFormat;
import java.time.Duration;
import java.time.Instant;
import java.util.HashSet;
import java.util.Set;

import io.nextsense.android.base.data.EegSample;
import io.nextsense.android.base.utils.Util;

/**
 * Listens to the samples and calculate the sample rate.
 */
public class SampleRateCalculator {

  public interface RateUpdateListener {
    void onRateUpdated(String formattedSampleRate, int skippedSamples);
  }

  private static final String TAG = SampleRateCalculator.class.getSimpleName();

  private final DecimalFormat sampleRateFormat = new DecimalFormat("###.##");
  private final Set<RateUpdateListener> rateUpdateListeners = new HashSet<>();
  private final int expectedSampleRate;
  private final Duration expectedSampleInterval;
  private Instant firstSampleReceptionTime;
  private Instant lastSamplingTime;
  private int samplesReceived;
  private String formattedSampleRate;
  private int skippedSamples;

  private SampleRateCalculator(int expectedSampleRate) {
    this.expectedSampleRate = expectedSampleRate;
    this.expectedSampleInterval = Duration.ofMillis(Math.round(1000.0f / expectedSampleRate));
    this.formattedSampleRate = "";
  }

  public static SampleRateCalculator create(int expectedSampleRate) {
    return new SampleRateCalculator(expectedSampleRate);
  }

  public void startListening() {
    EventBus.getDefault().register(this);
  }

  public void stopListening() {
    EventBus.getDefault().unregister(this);
  }

  @Subscribe(threadMode = ThreadMode.BACKGROUND)
  public void onEegSample(EegSample eegSample) {
    ++samplesReceived;
    if (firstSampleReceptionTime == null) {
      firstSampleReceptionTime = eegSample.getReceptionTimestamp();
      lastSamplingTime = eegSample.getAbsoluteSamplingTimestamp();
      return;
    }
    Duration timeDiff =
        Duration.between(eegSample.getAbsoluteSamplingTimestamp(), lastSamplingTime);
    if (timeDiff.compareTo(expectedSampleInterval) > 0) {
      long intervalSkippedSamples =
          timeDiff.dividedBy(expectedSampleInterval.toMillis()).toMillis();
      skippedSamples += intervalSkippedSamples;
      Log.w(TAG, "Skipped " + intervalSkippedSamples + " samples.");
    }
    if (samplesReceived % expectedSampleRate == 0) {
      float sampleRate = samplesReceived / ((eegSample.getReceptionTimestamp().toEpochMilli() -
          firstSampleReceptionTime.toEpochMilli()) / 1000.0f);
      formattedSampleRate = sampleRateFormat.format(sampleRate);
      Util.logv(TAG, "Sample rate: " + formattedSampleRate);
    }
    // Update listeners if any.
    for (RateUpdateListener rateUpdateListener : rateUpdateListeners) {
      rateUpdateListener.onRateUpdated(formattedSampleRate, skippedSamples);
    }
  }

  public void addRateUpdateListener(RateUpdateListener rateUpdateListener) {
    rateUpdateListeners.add(rateUpdateListener);
  }

  public void removeRateUpdateListener(RateUpdateListener rateUpdateListener) {
    rateUpdateListeners.remove(rateUpdateListener);
  }

  public String getSampleRate() {
    return formattedSampleRate;
  }

  public int getSkippedSamples() {
    return skippedSamples;
  }
}
