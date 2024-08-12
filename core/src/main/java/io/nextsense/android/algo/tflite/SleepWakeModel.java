package io.nextsense.android.algo.tflite;

import android.content.Context;

import brainflow.BrainFlowError;
import brainflow.DataFilter;

import com.google.common.primitives.Doubles;

import org.apache.commons.math3.complex.Complex;

import java.time.Duration;
import java.util.List;

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
  private static final int FFT_LENGTH = 1024;
  private static final int NOISE_FLOOR_DB = -90;

  public SleepWakeModel(Context context) {
    super(context, MODEL_NAME);
  }

  static void normalizeSpectrogram(float[] features, int noiseFloorDb, boolean clipAtOne) {
    final float noise = -1.0f * noiseFloorDb;
    final float noiseScale = 1.0f / (noise + 12.0f);

    for (int ix = 0; ix < features.length; ix++) {
      float f = features[ix];
      if (f < 1e-30f) {
        f = 1e-30f;
      }
      f = (float) Math.log10(f);
      f *= 10.0f; // scale by 10
      f += noise;
      f *= noiseScale;
      // clip again
      if (f < 0.0f) {
        f = 0.0f;
      } else if (f > 1.0f && clipAtOne) {
        f = 1.0f;
      }
      features[ix] = f;
    }
  }

  private static double[] calculatePsd(double[] data) {
    try {
      int fftLength = FFT_LENGTH;
      if (fftLength > data.length) {
        double[] paddedData = new double[fftLength];
        System.arraycopy(data, 0, paddedData, 0, data.length);
        data = paddedData;
      }

      // Perform FFT
      Complex[] fftResult = DataFilter.perform_fft(data, 0, fftLength, WindowOperations.NO_WINDOW);

      // Calculate the power spectrum
      double[] powerSpectrum = new double[(fftLength / 2) + 1];
      double meanRatio = 1.0 / fftLength;
      for (int i = 0; i < fftResult.length; i++) {
        powerSpectrum[i] = meanRatio * Math.pow(fftResult[i].abs(), 2);
        if (powerSpectrum[i] < 1e-10) {
          powerSpectrum[i] = 1e-10;
        }
      }
      return powerSpectrum;
    } catch (BrainFlowError error) {
      RotatingFileLogger.get().loge(TAG, "Error in calculating PSD: " + error.getMessage());
      return new double[0];
    }
  }

  public synchronized Boolean doInference(List<Float> data, float samplingRate) throws
      IllegalArgumentException {
    float frameStrideSeconds = FRAME_STRIDE.toMillis() / 1000f;
    float frameLengthSeconds = FRAME_LENGTH.toMillis() / 1000f;
    int numEpochs = (int) Math.floor(
        ((data.size() / samplingRate) / frameStrideSeconds) - 1);
    if (numEpochs < 7) {
      RotatingFileLogger.get().logw(TAG,
          "Input data is too small. Minimum input length is " + INPUT_LENGTH.getSeconds() +
              " seconds.");
      return null;
    }

    // Use last 400 samples if more were sent.
    if (numEpochs > 7) {
      data = data.subList(data.size() - (int)(INPUT_LENGTH.toSeconds() * samplingRate),
          data.size());
    }

    double[] downsampledData = Sampling.downsampleBF(Doubles.toArray(data), samplingRate,
        MODEL_INPUT_FREQUENCY);

    // Calculate the power spectrum of the downsampled data by FRAME_LENGTH, advancing by
    // FRAME_STRIDE.
    double[] powerSpectrum = new double[0];
    for (int i = 0; i < numEpochs; i++) {
      int startIdx = (int) (i * frameStrideSeconds * MODEL_INPUT_FREQUENCY);
      int endIdx = (int) ((i * frameStrideSeconds + frameLengthSeconds) *
          MODEL_INPUT_FREQUENCY);
      if (endIdx > downsampledData.length) {
        break;
      }
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

    normalizeSpectrogram(powerSpectrumFloat, NOISE_FLOOR_DB, false);

    // Run the inference.
    float[][] inferenceOutput = new float[1][NUM_SLEEP_STAGING_CATEGORIES];
    getTflite().run(powerSpectrumFloat, inferenceOutput);
    return inferenceOutput[0][0] > inferenceOutput[0][1];
  }
}
