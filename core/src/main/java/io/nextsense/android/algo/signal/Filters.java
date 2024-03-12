package io.nextsense.android.algo.signal;

import uk.me.berndporr.iirj.Butterworth;

public class Filters {

  private Filters() {}

  /*
  * Applies low pass filter
  * signal -- signal to be filtered
  * fs -- sampling frequency
  * order -- filter order
  * fc -- cutoff frequency
  */
  public static double[] applyLowPass(double[] signal, float fs, int order, float fc) {
    double[] filteredSig = new double[signal.length];
    Butterworth butterworth = new Butterworth();
    butterworth.lowPass(order, fs, fc);
    for (int i = 0; i < signal.length; i++) {
      filteredSig[i] = butterworth.filter(signal[i]);
    }
    return filteredSig;
  }

  /*
  * Applies high pass filter
  * signal -- signal to be filtered
  * fs -- sampling frequency
  * order -- filter order
  * fc -- cutoff frequency
  */
  public static double[] applyHighPass(double[] signal, float fs, int order, float fc) {
    double[] filteredSig = new double[signal.length];
    Butterworth butterworth = new Butterworth();
    butterworth.highPass(order, fs, fc);
    for (int i = 0; i < signal.length; i++) {
      filteredSig[i] = butterworth.filter(signal[i]);
    }
    return filteredSig;
  }

  /*
  * Applies band pass filter
  * signal -- signal to be filtered
  * fs -- sampling frequency
  * order -- filter order
  * lowPass -- low pass cutoff frequency
  * highPass -- high pass cutoff frequency
  */
  public static double[] applyBandPass(double[] signal, float fs, int order, float lowPass,
                                        float highPass) {
    double[] filtered_sig = applyLowPass(signal, order, (int) fs, highPass);
    filtered_sig = applyHighPass(filtered_sig, order, (int) fs, lowPass);
    return filtered_sig;
  }
}
