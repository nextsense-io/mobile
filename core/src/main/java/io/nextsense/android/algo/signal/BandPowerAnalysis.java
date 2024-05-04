package io.nextsense.android.algo.signal;

import org.apache.commons.math3.complex.Complex;
import org.apache.commons.math3.transform.DftNormalization;
import org.apache.commons.math3.transform.FastFourierTransformer;
import org.apache.commons.math3.transform.TransformType;
import jwave.Transform;
import jwave.transforms.FastWaveletTransform;
import jwave.transforms.wavelets.daubechies.Daubechies4;
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
  // TODO(eric): Have a setting to be able to select 50 Hertz when not in the USA.
  
  public static double getBandPower(List<Float> data, int samplingRate, double bandStart, double bandEnd) {
    if (data == null || data.isEmpty()) {
        throw new IllegalArgumentException("Data list cannot be null or empty.");
    }
    if (samplingRate <= 0) {
        throw new IllegalArgumentException("Sampling rate must be positive.");
    }
    if (bandStart < 0 || bandEnd <= bandStart) {
        throw new IllegalArgumentException("Invalid band frequency range.");
    }

    double[] dataArray = data.stream().mapToDouble(Float::doubleValue).toArray();

    dataArray = WaveletArtifactRejection.applyWaveletArtifactRejection(dataArray, "db4"); // Apply wavelet artifact rejection

    dataArray = Filters.applyBandStop(dataArray, samplingRate, 8, 60, 2);
    dataArray = Filters.applyBandPass(dataArray, samplingRate, 4, 0.1f, 50);

    int segmentSize = 256; // Usual value
    int overlap = segmentSize / 2; // 50% overlap (usual value)
    double[] averagedPowerSpectrum = computeWelchPSD(dataArray, samplingRate, segmentSize, overlap);

    return calculateBandPower(averagedPowerSpectrum, samplingRate, bandStart, bandEnd);
}

  private static double[] computeWelchPSD(double[] dataArray, int samplingRate, int segmentSize, int overlap) {
  if (segmentSize > dataArray.length) {
      throw new IllegalArgumentException("Segment size must be less than or equal to the length of the data array.");
  }

  FastFourierTransformer transformer = new FastFourierTransformer(DftNormalization.STANDARD);
  int numSegments = (dataArray.length - overlap) / (segmentSize - overlap);
  double[][] powerSpectra = new double[numSegments][];

  for (int i = 0; i < numSegments; i++) {
      int start = i * (segmentSize - overlap);
      double[] segment = Arrays.copyOfRange(dataArray, start, start + segmentSize);
      windowFunction(segment);
      Complex[] fftResult = transformer.transform(segment, TransformType.FORWARD);
      powerSpectra[i] = Arrays.stream(fftResult).mapToDouble(c -> c.abs() * c.abs()).toArray();
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

  private static double calculateBandPower(double[] powerSpectrum, int fs, double lowFreq, double highFreq) {
    int startIndex = (int)(lowFreq / fs * powerSpectrum.length);
    int endIndex = (int)(highFreq / fs * powerSpectrum.length);
    double bandPower = 0;
    for (int i = startIndex; i <= endIndex; i++) {
        bandPower += powerSpectrum[i];
    }
    return bandPower / (endIndex - startIndex + 1);
    }

    private static int getNextPowerOfTwo(int n) {
      return (int) Math.pow(2, Math.ceil(Math.log(n) / Math.log(2)));
  }
}

public class WaveletArtifactRejection {

    private static final double Kp = 0.02; // Proportional gain for the control mechanism
    private static final double desiredError = 0.05; // Desired baseline error for optimal performance

    private static final double maxFactor = 0.1; // Upper and lower bounds for the noise estimation factor
    private static final double minFactor = 0.01;

    private static double noiseEstimationFactor = 0.01; // Initial estimation factor
    private static double noiseLevel = 0.0; // Initial noise level estimate

    public static double[] applyWaveletArtifactRejection(double[] data, String waveletType) {
        if (data == null || data.length == 0) {
            throw new IllegalArgumentException("Data array cannot be null or empty.");
        }

      try {
        Transform transform = new Transform(new FastWaveletTransform(new Daubechies4()));
        double[] transformedData = transform.forward(data);

        updateNoiseLevel(transformedData); // Update noise level based on current data

        double threshold = calculateAdaptiveThreshold(); // Calculate threshold based on updated noise level

        applyThreshold(transformedData, threshold); // Apply thresholding to remove artifacts

        double[] reconstructedData = transform.reverse(transformedData); // Reconstruct the signal

        adjustNoiseEstimationFactor(data, reconstructedData); // Adjust the factor based on signal quality

        return reconstructedData;
    } catch (Exception e) {
        throw new RuntimeException("Failed to apply wavelet artifact rejection due to: " + e.getMessage(), e);
    }
  }

  private static void updateNoiseLevel(double[] detailCoefficients) {
      double currentNoiseEstimate = calculateMedian(detailCoefficients);
      noiseLevel = noiseEstimationFactor * currentNoiseEstimate + (1 - noiseEstimationFactor) * noiseLevel;
  }

  private static double calculateAdaptiveThreshold() {
      return noiseLevel * Math.sqrt(2 * Math.log(detailCoefficients.length));
  }

  private static void applyThreshold(double[] data, double threshold) {
      for (int i = data.length / 2; i < data.length; i++) {
          data[i] = Math.abs(data[i]) < threshold ? 0 : data[i];
      }
  }

  private static void adjustNoiseEstimationFactor(double[] originalData, double[] reconstructedData) {
    double error = calculateSignalError(originalData, reconstructedData);

    double errorDifference = error - desiredError; // Calculate the difference from the desired error

    double adjustment = Kp * errorDifference; // Calculate adjustment based on proportional control

    noiseEstimationFactor += adjustment; // Adjust the noise estimation factor

    noiseEstimationFactor = Math.min(Math.max(noiseEstimationFactor, minFactor), maxFactor); // Constrain the factor to be within set bounds
  }

  private static double calculateSignalError(double[] original, double[] reconstructed) {
    double sumError = 0;
    for (int i = 0; i < original.length; i++) {
        sumError += Math.pow(original[i] - reconstructed[i], 2);
    }
    return Math.sqrt(sumError / original.length);
  }

  private static double calculateMedian(double[] data) {
      double[] sorted = Arrays.copyOf(data, data.length);
      Arrays.sort(sorted);
      int middle = sorted.length / 2;
      if (sorted.length % 2 == 0) {
          return (sorted[middle - 1] + sorted[middle]) / 2.0;
      } else {
          return sorted[middle];
      }
  }
}
