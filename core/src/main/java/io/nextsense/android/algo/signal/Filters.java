package io.nextsense.android.algo.signal;

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
}
