package io.nextsense.android.algo.signal;

import android.util.Log;

import java.util.Arrays;

import io.nextsense.android.algo.MathUtils;
import jwave.Transform;
import jwave.transforms.FastWaveletTransform;
import jwave.transforms.wavelets.daubechies.Daubechies4;

public class WaveletArtifactRejection {

  private WaveletArtifactRejection() {
    // Prevent instantiation
  }


  private static final String TAG = WaveletArtifactRejection.class.getSimpleName();
  private static final double KP = 0.02; // Proportional gain for the control mechanism
  private static final double DESIRED_ERROR = 0.05; // Desired baseline error for optimal performance

  private static final double MAX_FACTOR = 0.1; // Upper and lower bounds for the noise estimation factor
  private static final double MIN_FACTOR = 0.01;

  private static double noiseEstimationFactor = 0.01; // Initial estimation factor
  private static double noiseLevel = 0.0; // Initial noise level estimate


  /**
   * Get the data that is a power of 2.
   * @param data
   * @return The data that is a power of 2.
   */
  public static double[] getPowerOf2DataSize(double[] data) {
    // Ensure the data array is a power of 2.
    int effectiveSamplesNumber = MathUtils.biggestPowerOfTwoUnder(data.length);
    Log.d(TAG, "Number of samples: " + data.length + ", Effective samples number: " +
        effectiveSamplesNumber);
    return Arrays.copyOfRange(data, data.length - effectiveSamplesNumber, data.length);
  }

  /**
   * Apply wavelet artifact rejection to the given data. It needs to be a length that is a power
   * of 2.
   * @param data
   * @return The data with wavelet artifact rejection applied.
   */
  public static double[] applyWaveletArtifactRejection(double[] data) {
    if (data == null || data.length == 0) {
      Log.w(TAG, "Data array cannot be null or empty.");
      return data;
    }

    try {
      Transform transform = new Transform(new FastWaveletTransform(new Daubechies4()));
      double[] transformedData = transform.forward(data);

      updateNoiseLevel(transformedData); // Update noise level based on current data

      double threshold = calculateAdaptiveThreshold(transformedData); // Calculate threshold based on updated noise level

      applyCardiacArtifactThreshold(transformedData, threshold); // Apply thresholding to remove cardiac artifacts

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

  private static double calculateAdaptiveThreshold(double[] detailCoefficients) {
    return noiseLevel * Math.sqrt(2 * Math.log(detailCoefficients.length));
  }

  private static void applyCardiacArtifactThreshold(double[] data, double baseThreshold) {
    // Dynamic thresholding (computed on the variability of wavelet coefficients)
    double[] detailCoefficients = Arrays.copyOfRange(data, data.length / 2, data.length);
    double medianValue = calculateMedian(detailCoefficients);
    double mad = calculateMAD(detailCoefficients, medianValue); // Median Absolute Deviation
    double dynamicThreshold = baseThreshold * mad; // Adjust threshold dynamically

    for (int i = 0; i < detailCoefficients.length; i++) {
        if (Math.abs(detailCoefficients[i]) < dynamicThreshold) {
            detailCoefficients[i] = 0; // Reproducing JB's assumption by setting coefficients below threshold to zero
        }
    }

    // Finally, copying the modified coefficients back to the original data array
    System.arraycopy(detailCoefficients, 0, data, data.length / 2, detailCoefficients.length);
  }

  private static double calculateMAD(double[] data, double median) {
    double[] deviations = new double[data.length];
    for (int i = 0; i < data.length; i++) {
        deviations[i] = Math.abs(data[i] - median);
    }
    return calculateMedian(deviations);
  }

  private static void adjustNoiseEstimationFactor(double[] originalData, double[] reconstructedData) {
    double error = calculateSignalError(originalData, reconstructedData);

    double errorDifference = error - DESIRED_ERROR; // Calculate the difference from the desired error

    double adjustment = KP * errorDifference; // Calculate adjustment based on proportional control

    noiseEstimationFactor += adjustment; // Adjust the noise estimation factor

    noiseEstimationFactor = Math.min(Math.max(noiseEstimationFactor, MIN_FACTOR), MAX_FACTOR); // Constrain the factor to be within set bounds
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
