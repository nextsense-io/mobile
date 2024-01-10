package io.nextsense.android.algo.signal;

import uk.me.berndporr.iirj.Butterworth;

public class Filters {

  private Filters() {}

  /*
  * Applies low pass filter
  * fs -- sampling frequency
  * order -- filter order
  * fc -- cutoff frequency
  */
  public static double[] applyLowPass(double[] sig, float fs, int order, float fc) {
    double[] filteredSig = new double[sig.length];
    Butterworth butterworth = new Butterworth();
    butterworth.lowPass(order, fs, fc);
    for (int i = 0; i < sig.length; i++) {
      filteredSig[i] = butterworth.filter(sig[i]);
    }
    return filteredSig;
  }

  /*
  * Applies band pass filter
  * fs -- sampling frequency
  * order -- filter order
  * fc -- cutoff frequency
  */
  public static double[] applyBandPass(double[] sig, float fs, int order, float lowPass,
                                       float highPass) {
    double[] filteredSig = new double[sig.length];

    float nyq = (float)0.5*fs;
    lowPass = lowPass / nyq;
    highPass = highPass / nyq;
    float centreFreq = (lowPass + highPass) / 2;
    float width = highPass - lowPass;

    Butterworth butterworth = new Butterworth();
    butterworth.bandPass(order, fs, centreFreq, width);
    for (int i = 0; i < sig.length; i++) {
      filteredSig[i] = butterworth.filter(sig[i]);
    }
    return filteredSig;
  }
}
