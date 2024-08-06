package io.nextsense.android.algo.signal;

import android.util.Log;

import java.util.Objects;

import brainflow.BrainFlowError;
import brainflow.DataFilter;
import brainflow.FilterTypes;
import brainflow.NoiseTypes;
import uk.me.berndporr.iirj.Butterworth;

public class Filters {

  private Filters() {}

  /*
  * Applies low pass filter
  * signal -- signal to be filtered
  * samplingRate -- sampling frequency
  * order -- filter order
  * cutoff -- cutoff frequency
  */
  public static double[] applyLowPass(
      double[] signal, float samplingRate, int order, float cutoff) {
    double[] filteredSig = new double[signal.length];
    Butterworth butterworth = new Butterworth();
    butterworth.lowPass(order, samplingRate, cutoff);
    for (int i = 0; i < signal.length; i++) {
      filteredSig[i] = butterworth.filter(signal[i]);
    }
    return filteredSig;
  }

  /*
  * Applies high pass filter
  * signal -- signal to be filtered
  * samplingRate -- sampling frequency
  * order -- filter order
  * cutoff -- cutoff frequency
  */
  public static double[] applyHighPass(
      double[] signal, float samplingRate, int order, float cutoff) {
    double[] filteredSig = new double[signal.length];
    Butterworth butterworth = new Butterworth();
    butterworth.highPass(order, samplingRate, cutoff);
    for (int i = 0; i < signal.length; i++) {
      filteredSig[i] = butterworth.filter(signal[i]);
    }
    return filteredSig;
  }

  /*
  * Applies band pass filter
  * signal -- signal to be filtered
  * samplingRate -- sampling frequency
  * order -- filter order
  * lowCutoff -- low pass cutoff frequency
  * highCutoff -- high pass cutoff frequency
  */
  public static double[] applyBandPass(double[] signal, float samplingRate, int order,
                                       float lowCutoff, float highCutoff) {
    double[] filteredSignal = applyLowPass(signal, (int) samplingRate, order, highCutoff);
    filteredSignal = applyHighPass(filteredSignal, (int) samplingRate, order, lowCutoff);
    return filteredSignal;
  }

  public static void applyBandPassBF(double[] signal, float samplingRate, int order,
                                       float lowCutoff, float highCutoff) {
    try {
      DataFilter.perform_bandpass(signal, (int) samplingRate, lowCutoff, highCutoff, order,
          FilterTypes.BUTTERWORTH, /*ripple=*/0.0);
    } catch (BrainFlowError error) {
      Log.e("Filters", Objects.requireNonNull(error.getMessage()));
    }
  }

  /*
   * Applies band stop filter
   * signal -- signal to be filtered
   * samplingRate -- sampling frequency
   * order -- filter order
   * centerFrequency -- center frequency
   * widthFrequency -- width frequency
   */
  public static double[] applyBandStop(double[] signal, float samplingRate, int order,
                                       float centerFrequency, float widthFrequency) {
    Butterworth butterworth = new Butterworth();
    butterworth.bandStop(order, samplingRate, centerFrequency, widthFrequency);
    double[] filteredSig = new double[signal.length];
    for (int i = 0; i < signal.length; i++) {
      filteredSig[i] = butterworth.filter(signal[i]);
    }
    return filteredSig;
  }

  public static void removeEnvironmentalNoise(
      double[] signal, float samplingRate, int centerFrequency) {
    NoiseTypes noiseType = centerFrequency == 50 ? NoiseTypes.FIFTY : NoiseTypes.SIXTY;
    try {
      DataFilter.remove_environmental_noise(signal, (int) samplingRate, noiseType.get_code());
    } catch (BrainFlowError error) {
      Log.e("Filters", Objects.requireNonNull(error.getMessage()));
    }
  }
}
