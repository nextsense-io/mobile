package io.nextsense.android.algo.tflite;

import android.content.Context;

import com.google.common.primitives.Floats;

import org.tensorflow.lite.Interpreter;

import java.io.IOException;
import java.nio.FloatBuffer;
import java.time.Duration;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.nextsense.android.base.utils.RotatingFileLogger;

public class SleepTransformerModel extends BaseModel {

  public static final Duration EPOCH_LENGTH = Duration.ofSeconds(30);
  public static final int INPUT_EPOCHS_SIZE = 21;
  public static final int POSTPROCESSING_RESULTS_INDEX = 0;
  public static final int POSTPROCESSING_CONFIDENCES_INDEX = 1;
  private static final String TAG = SleepTransformerModel.class.getSimpleName();
  private static final String PREPROCESSOR_NAME = "sleep_stage_preprocessor.tflite";
  private static final String MODEL_NAME = "sleep_stage_classifier.tflite";
  private static final String POSTPROCESSOR_NAME = "sleep_stage_postprocessor.tflite";
  private static final int NUM_SLEEP_STAGING_CATEGORIES = 5;

  private Interpreter preprocessorTflite;
  private Interpreter postprocessorTflite;

  public SleepTransformerModel(Context context) {
    super(context, MODEL_NAME);
  }

  @Override
  public void loadModel() throws IOException {
    super.loadModel();
    if (preprocessorTflite != null) {
      RotatingFileLogger.get().logi(TAG, "Preprocessor model already loaded.");
    } else {
      preprocessorTflite = loadModelAsset(PREPROCESSOR_NAME);
    }
    if (postprocessorTflite != null) {
      RotatingFileLogger.get().logi(TAG, "Postprocessor model already loaded.");
    } else {
      postprocessorTflite = loadModelAsset(POSTPROCESSOR_NAME);
    }
  }

  @Override
  public void closeModel() {
    super.closeModel();
    if (preprocessorTflite != null) {
      preprocessorTflite.close();
      preprocessorTflite = null;
    }
    if (postprocessorTflite != null) {
      postprocessorTflite.close();
      postprocessorTflite = null;
    }
  }

  public Map<Integer, Object> doInference(List<Float> data, float samplingRate) throws
      IllegalArgumentException {
    int numEpochs = (int)Math.round(Math.floor(
        (data.size() / samplingRate) / (int) EPOCH_LENGTH.getSeconds()));
    if (numEpochs > INPUT_EPOCHS_SIZE) {
      RotatingFileLogger.get().logw(TAG,
          "Input data is too long. Max input length is " + INPUT_EPOCHS_SIZE + " epochs." +
          "Ignoring the rest of the data.");
    }
    int inputSize = INPUT_EPOCHS_SIZE * (int) EPOCH_LENGTH.getSeconds() * (int) samplingRate;
    if (data.size() < inputSize) {
      String errorText = "Input data is too short. Min input length is " + inputSize + " samples.";
      RotatingFileLogger.get().logw(TAG, errorText);
      return new HashMap<>();
    }

    // Run the preprocessor.
    float[] preprocessingData = new float[inputSize];
    int copySize = Math.min(data.size(), inputSize);
    int srcPos = Math.max(0, data.size() - inputSize);
    Arrays.fill(preprocessingData, 0.0f);
    System.arraycopy(Floats.toArray(data), srcPos, preprocessingData, 0, copySize);
    float[][][][][] preprocessingOutput = new float[1][INPUT_EPOCHS_SIZE][29][128][1];
    preprocessorTflite.run(preprocessingData, preprocessingOutput);

    // Run the inference.
    float[][][] inferenceOutput = new float[1][INPUT_EPOCHS_SIZE][NUM_SLEEP_STAGING_CATEGORIES];
    Object[] inferenceInputs = new Object[]{preprocessingOutput, false};
    Map<Integer, Object> inferenceOutputs = new HashMap<>();
    inferenceOutputs.put(POSTPROCESSING_RESULTS_INDEX, inferenceOutput);
    getTflite().runForMultipleInputsOutputs(inferenceInputs, inferenceOutputs);

    // The run postprocessor.
    Map<Integer, Object> mapOfIndicesToOutputs = new HashMap<>();
    String[] resultsOutput = new String[INPUT_EPOCHS_SIZE];
    mapOfIndicesToOutputs.put(POSTPROCESSING_RESULTS_INDEX, resultsOutput);
    FloatBuffer confidencesOutput = FloatBuffer.allocate(INPUT_EPOCHS_SIZE);
    mapOfIndicesToOutputs.put(POSTPROCESSING_CONFIDENCES_INDEX, confidencesOutput);
    Object[] inferenceOutputWrapper = new Object[]{inferenceOutput};
    postprocessorTflite.runForMultipleInputsOutputs(inferenceOutputWrapper, mapOfIndicesToOutputs);

    // Put the backing array in the result that is returned instead of the buffer.
    mapOfIndicesToOutputs.put(POSTPROCESSING_CONFIDENCES_INDEX, confidencesOutput.array());
    return mapOfIndicesToOutputs;
  }
}
