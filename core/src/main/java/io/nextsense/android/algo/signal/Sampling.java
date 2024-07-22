package io.nextsense.android.algo.signal;

import org.apache.commons.math3.analysis.interpolation.SplineInterpolator;
import org.apache.commons.math3.analysis.polynomials.PolynomialSplineFunction;

import java.util.Arrays;


public class Sampling {

  private Sampling() {}

  /* Function to resample the signal with an anti-aliasing filter. */
  public static double[] resample(double[] signal, float rawFs, int order, float newFs) {
    // apply anti-aliasing filter.
    float nyquist = newFs / 2;
    signal = Filters.applyLowPass(signal, rawFs, order, nyquist - 2);

    // resample the signal.
    signal = resamplePoly(signal, newFs, rawFs);

    return signal;
  }

  /* Helper function to resample according to resample_poly of numpy. */
  public static double[] resamplePoly(double[] signal, float up, float down) {
    // Generate original x values.
    double[] xOriginal = new double[signal.length];
    for (int i = 0; i < signal.length; i++) {
      xOriginal[i] = i;
    }

    // Perform polynomial spline interpolation.
    SplineInterpolator interpolator = new SplineInterpolator();
    PolynomialSplineFunction splineFunction = interpolator.interpolate(xOriginal, signal);

    // Generate new x values for the resampled signal.
    double[] xResampled = generateNewX(signal.length, up, down);

    // Evaluate the interpolated function at the new x values.
    return Arrays.stream(xResampled).map(splineFunction::value).toArray();
  }

  /* Helper function for resamplePoly function. Used in data interpolation. */
  private static double[] generateNewX(int originalLength, float up, float down) {
    int newLength = (int) (originalLength * up / down);
    double[] xResampled = new double[newLength];

    for (int i = 0; i < newLength; i++) {
      xResampled[i] = (double) i / (double) (newLength - 1) * (originalLength - 1);
    }

    return xResampled;
  }
}
