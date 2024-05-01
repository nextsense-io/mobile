package io.nextsense.android.algo.signal;

import org.apache.commons.math3.complex.Complex;
import org.apache.commons.math3.transform.DftNormalization;
import org.apache.commons.math3.transform.FastFourierTransformer;
import org.apache.commons.math3.transform.TransformType;

import java.util.Arrays;
import java.util.List;

public class BandPowerAnalysis {
  public enum Band {
    DELTA(1.0, 4.0),
    THETA(4.0, 8.0),
    ALPHA(8.0, 12.0),
    BETA(12.0, 30.0),
    GAMMA(30.0, 49.0);

    private final double start;
    private final double end;

    Band(double start, double end) {
      this.start = start;
      this.end = end;
    }

    public double getStart() {
      return start;
    }

    public double getEnd() {
      return end;
    }
  }

  public static double getBandPower(List<Float> signal, int samplingRate, Band band) {
    return getBandPower(signal, samplingRate, band.getStart(), band.getEnd());
  }

  public static double getBandPower(
      List<Float> data, int samplingRate, double bandStart, double bandEnd) {
    FastFourierTransformer transformer = new FastFourierTransformer(DftNormalization.STANDARD);
    double[] fftDataArray = new double[getNextPowerOfTwo(data.size())];
    Arrays.fill(fftDataArray, data.size(), fftDataArray.length, 0.0f);
    double[] dataArray = data.stream().mapToDouble(aFloat -> aFloat).toArray();
    // TODO(eric): Have a setting to be able to select 50 Hertz when not in the USA.
    dataArray = Filters.applyBandStop(dataArray, samplingRate, 8, 60, 2);
    dataArray = Filters.applyBandPass(dataArray, samplingRate, 4, 0.1f, 50);
    System.arraycopy(dataArray, 0, fftDataArray, 0, dataArray.length);
    Complex[] complexResult = transformer.transform(fftDataArray, TransformType.FORWARD);
    double[] powerSpectrum = new double[complexResult.length];
    for (int i = 0; i < complexResult.length; i++) {
      powerSpectrum[i] = complexResult[i].abs();
    }
    return calculateBandPower(powerSpectrum, samplingRate, bandStart, bandEnd);
  }

  private static double calculateBandPower(
      double[] powerSpectrum, int fs, double lowFreq, double highFreq) {
    int startIndex = (int)(lowFreq / fs * powerSpectrum.length);
    int endIndex = (int)(highFreq / fs * powerSpectrum.length);
    double bandPower = 0;
    int resultsSize = 0;
    for (int i = startIndex; i <= endIndex; i++) {
      bandPower += powerSpectrum[i];
      resultsSize++;
    }
    return bandPower / resultsSize;
  }

  private static int getNextPowerOfTwo(int n) {
    return (int) Math.pow(2, Math.ceil(Math.log(n) / Math.log(2)));
  }
}