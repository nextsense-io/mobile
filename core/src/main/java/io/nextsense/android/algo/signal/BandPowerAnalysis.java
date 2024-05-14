package io.nextsense.android.algo.signal;

import android.util.Log;

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

  public static double getBandPower(
      List<Float> signal, int samplingRate, Band band, Double powerLineFrequency) {
    return getBandPower(signal, samplingRate, band.getStart(), band.getEnd(), powerLineFrequency);
  }
  
  private static double calculatePower(double[] signal) {
      double power = 0;
      for (double amplitude : signal) {
          power += amplitude * amplitude;
      }
      return power / signal.length;
  }

  private static double calculateSNR(double signalPower, double noisePower) {
      return 10 * Math.log10(signalPower / noisePower);
  }

  public static double getBandPower(
      List<Float> data, int samplingRate, double bandStart, double bandEnd,
      Double powerLineFrequency) {
    if (data == null || data.isEmpty()) {
        throw new IllegalArgumentException("Data list cannot be null or empty.");
    }
    if (data.size() < 8192) {
        Log.w("TAG", "Data list must contain at least 8192 samples.");
        return 0;
    }
    if (samplingRate <= 0) {
        throw new IllegalArgumentException("Sampling rate must be positive.");
    }
    if (bandStart < 0 || bandEnd <= bandStart) {
        throw new IllegalArgumentException("Invalid band frequency range.");
    }

    double[] dataArray = data.stream().mapToDouble(Float::doubleValue).toArray();
    // Ensure the data array is 8192 samples long.
    dataArray = Arrays.copyOfRange(dataArray, dataArray.length - 8192, dataArray.length);

    // Original signal power calculation for SNR
    double originalPower = calculatePower(dataArray);

    // Apply wavelet artifact rejection using Daubechies 4 wavelet,
    dataArray = WaveletArtifactRejection.applyWaveletArtifactRejection(dataArray, "db4");

    // After processing signal power calculation for SNR
    double processedPower = calculatePower(dataArray);

    // Calculate and log SNR improvements
    double originalSNR = calculateSNR(originalPower, originalPower - processedPower); // Example computation
    double processedSNR = calculateSNR(processedPower, originalPower - processedPower); // Example computation

    Log.d("SNR", "Original SNR: " + originalSNR + " dB");
    Log.d("SNR", "Processed SNR: " + processedSNR + " dB");

    if (powerLineFrequency != null) {
      dataArray = Filters.applyBandStop(
          dataArray, samplingRate, 4, powerLineFrequency.floatValue(), 2);
    }
    dataArray = Filters.applyBandPass(dataArray, samplingRate, 4, 0.1f, 50);

    int segmentSize = 256; // Usual value
    int overlap = segmentSize / 2; // 50% overlap (usual value)
    double[] averagedPowerSpectrum = computeWelchPSD(dataArray, segmentSize, overlap);

    return calculateBandPower(averagedPowerSpectrum, samplingRate, bandStart, bandEnd);
  }
  
  private static double[] computeWelchPSD(
      double[] dataArray, int segmentSize, int overlap) {
    if (segmentSize > dataArray.length) {
        throw new IllegalArgumentException(
            "Segment size must be less than or equal to the length of the data array.");
    }

    FastFourierTransformer transformer = new FastFourierTransformer(DftNormalization.STANDARD);
    int numSegments = (dataArray.length - overlap) / (segmentSize - overlap);
    double[][] powerSpectra = new double[numSegments][];
    double[] frequencyFactor = new double[segmentSize];

    // Minimum frequency to avoid too high compensation
    double minFrequency = 0.1; // Usual value (could be modified if lower in practice)
    double maxFactor = 1.0 / minFrequency;

    // Calculate 1/f factors for each frequency index, we apply a cap to avoid excessive compensation
    for (int i = 0; i < segmentSize; i++) {
        double frequency = i * samplingRate / (double) segmentSize;
        frequencyFactor[i] = (frequency > minFrequency) ? 1.0 / frequency : maxFactor;
    }

    for (int i = 0; i < numSegments; i++) {
        int start = i * (segmentSize - overlap);
        double[] segment = Arrays.copyOfRange(dataArray, start, start + segmentSize);
        // Apply a window function to reduce spectral leakage
        windowFunction(segment); 
        Complex[] fftResult = transformer.transform(segment, TransformType.FORWARD);
        powerSpectra[i] = new double[segmentSize];
        for (int j = 0; j < segmentSize; j++) {
            powerSpectra[i][j] = fftResult[j].abs() * fftResult[j].abs() * frequencyFactor[j]; // Apply 1/f compensation here
        }
    }

    double[] averagedPowerSpectrum = new double[segmentSize];
    Arrays.fill(averagedPowerSpectrum, 0);
    for (int i = 0; i < segmentSize; i++) {
        for (double[] spectrum : powerSpectra) {
            averagedPowerSpectrum[i] += spectrum[i];
        }
        averagedPowerSpectrum[i] /= numSegments;
    }
    return averagedPowerSpectrum;
  }

  private static void windowFunction(double[] segment) {
    // Apply a Hamming window
    for (int i = 0; i < segment.length; i++) {
        segment[i] *= 0.54 - 0.46 * Math.cos(2 * Math.PI * i / (segment.length - 1));
    }
  }

  private static double calculateBandPower(
      double[] powerSpectrum, int fs, double lowFreq, double highFreq) {
    int startIndex = (int)(lowFreq / fs * powerSpectrum.length);
    int endIndex = (int)(highFreq / fs * powerSpectrum.length);
    double bandPower = 0;
    for (int i = startIndex; i <= endIndex; i++) {
        bandPower += powerSpectrum[i];
    }
    return bandPower / (endIndex - startIndex + 1);
  }
}
