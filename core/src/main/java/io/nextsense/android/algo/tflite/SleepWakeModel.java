package io.nextsense.android.algo.tflite;

import android.content.Context;

import brainflow.BrainFlowError;
import brainflow.DataFilter;

import com.google.common.primitives.Doubles;

import org.apache.commons.math3.complex.Complex;

import java.time.Duration;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import brainflow.WindowOperations;
import io.nextsense.android.algo.signal.Sampling;
import io.nextsense.android.base.utils.RotatingFileLogger;


public class SleepWakeModel extends BaseModel {

  public static final Duration FRAME_LENGTH = Duration.ofSeconds(1);
  public static final Duration FRAME_STRIDE = Duration.ofMillis(500);
  public static final Duration INPUT_LENGTH = Duration.ofSeconds(4);
  public static final float MODEL_INPUT_FREQUENCY = 200f;
  private static final String TAG = SleepWakeModel.class.getSimpleName();
  private static final String MODEL_NAME = "sleep_wake.tflite";
  private static final int NUM_SLEEP_STAGING_CATEGORIES = 2;

  public SleepWakeModel(Context context) {
    super(context, MODEL_NAME);
  }

  private static double[] calculatePsd(double[] data) {
    try {
      int fftLength = DataFilter.get_nearest_power_of_two(data.length);

      // Perform FFT
      Complex[] fftResult = DataFilter.perform_fft(data, 0, fftLength, WindowOperations.NO_WINDOW);

      // Calculate the power spectrum
      double[] powerSpectrum = new double[fftLength / 2];
      for (int i = 0; i < fftLength / 2; i++) {
        powerSpectrum[i] = Math.pow(fftResult[2 * i].abs(), 2);
      }
      return powerSpectrum;
    } catch (BrainFlowError error) {
      RotatingFileLogger.get().loge(TAG, "Error in calculating PSD: " + error.getMessage());
      return new double[0];
    }
  }

  public Map<Integer, Object> doInference(List<Float> data, float samplingRate) throws
      IllegalArgumentException {
    int numEpochs = (int)Math.round(Math.floor(
        (data.size() / samplingRate) / FRAME_STRIDE.getSeconds() / 2) - 1);
    if (numEpochs < 1) {
      RotatingFileLogger.get().logw(TAG,
          "Input data is too small. Minimum input length is " + INPUT_LENGTH.getSeconds() +
              " seconds.");
      return new HashMap<>();
    }

    double[] downsampledData = Sampling.downsampleBF(Doubles.toArray(data), samplingRate,
        MODEL_INPUT_FREQUENCY);

    // Calculate the power spectrum of the downsampled data by FRAME_LENGTH, advancing by
    // FRAME_STRIDE.
    double[] powerSpectrum = new double[0];
    for (int i = 0; i < numEpochs; i++) {
      int startIdx = (int) (i * FRAME_STRIDE.getSeconds() * MODEL_INPUT_FREQUENCY);
      int endIdx = (int) ((i * FRAME_STRIDE.getSeconds() + FRAME_LENGTH.getSeconds()) *
          MODEL_INPUT_FREQUENCY);
      double[] frameData = new double[endIdx - startIdx];
      System.arraycopy(downsampledData, startIdx, frameData, 0, frameData.length);
      double[] framePowerSpectrum = calculatePsd(frameData);
      powerSpectrum = Doubles.concat(powerSpectrum, framePowerSpectrum);
    }

    // The model need float input.
    float[] powerSpectrumFloat = new float[powerSpectrum.length];
    for (int i = 0; i < powerSpectrum.length; i++) {
      powerSpectrumFloat[i] = (float) (powerSpectrum[i]);
    }

    // Run the inference.
    float[][] inferenceOutput = new float[numEpochs][NUM_SLEEP_STAGING_CATEGORIES];
    // Map<Integer, Object> inferenceOutputs = new HashMap<>();
    getTflite().run(powerSpectrumFloat, inferenceOutput);

    // Put the backing array in the result that is returned instead of the buffer.
    // mapOfIndicesToOutputs.put(POSTPROCESSING_CONFIDENCES_INDEX, confidencesOutput.array());
    return new HashMap<>();
  }
}
