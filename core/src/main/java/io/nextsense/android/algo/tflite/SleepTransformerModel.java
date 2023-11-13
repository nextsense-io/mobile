package io.nextsense.android.algo.tflite;

import android.content.Context;

import com.google.common.primitives.Floats;

import org.tensorflow.lite.Interpreter;
import org.tensorflow.lite.Tensor;

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
  public static final int MAX_INPUT_EPOCHS = 21;
  public static final int POSTPROCESSING_RESULTS_INDEX = 0;
  public static final int POSTPROCESSING_CONFIDENCES_INDEX = 1;
  private static final int PREPROCESSING_INPUT_DATA_INDEX = 0;
  private static final String TAG = SleepTransformerModel.class.getSimpleName();
  private static final String PREPROCESSOR_NAME = "sleep_stage_preprocessor.tflite";
  private static final String MODEL_NAME = "sleep_stage_classifier.tflite";
  private static final String POSTPROCESSOR_NAME = "sleep_stage_postprocessor.tflite";

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
    if (numEpochs > MAX_INPUT_EPOCHS) {
      RotatingFileLogger.get().logw(TAG,
          "Input data is too long. Max input length is " + MAX_INPUT_EPOCHS + " epochs." +
          "Ignoring the rest of the data.");
      numEpochs = MAX_INPUT_EPOCHS;
    }
    int inputSize = MAX_INPUT_EPOCHS * (int) EPOCH_LENGTH.getSeconds() * (int) samplingRate;
    if (data.size() < inputSize) {
      String errorText = "Input data is too short. Min input length is " + inputSize + " samples.";
      RotatingFileLogger.get().logw(TAG, errorText);
      // throw new IllegalArgumentException(errorText);
    }

    float[] preprocessingData = new float[inputSize];
    float[][][][][] preprocessingOutput = new float[1][21][29][128][1];
    int copySize = Math.min(data.size(), inputSize);
    int srcPos = Math.max(0, data.size() - inputSize);
    System.arraycopy(Floats.toArray(data), srcPos, preprocessingData, 0, copySize);
    Arrays.fill(preprocessingData, 0.0f);
    FloatBuffer floatBuffer = FloatBuffer.allocate(1 * 21 * 29 * 128 * 1);

    Map<String, Object> inputs = new HashMap<>();
    inputs.put("index", preprocessingData);
    Map<String, Object> outputs = new HashMap<>();
    outputs.put("index", floatBuffer);

    // Run the preprocessor.
    preprocessorTflite.run(preprocessingData, floatBuffer);

    Map<Integer, Object> mapOfIndicesToInputs = new HashMap<>();
//    String[] resultsOutput = new String[numEpochs];
//    mapOfIndicesToInputs.put(0, preprocessingOutput);
//    FloatBuffer confidencesOutput = FloatBuffer.allocate(numEpochs);
//    mapOfIndicesToInputs.put(1, false);
//    Map<Integer, Object> mapOfIndicesOutputs = new HashMap<>();
//    float[][][] inferenceOutput = new float[1][21][5];
//    mapOfIndicesOutputs.put(0, inferenceOutput);
//    getTflite().
//    getTflite().runForMultipleInputsOutputs(mapOfIndicesToInputs, mapOfIndicesOutputs);
//
//
//    Map<Integer, Object> mapOfIndicesToOutputs = new HashMap<>();
//    String[] resultsOutput = new String[numEpochs];
//    mapOfIndicesToOutputs.put(RESULTS_INDEX, resultsOutput);
//    FloatBuffer confidencesOutput = FloatBuffer.allocate(numEpochs);
//    mapOfIndicesToOutputs.put(CONFIDENCES_INDEX, confidencesOutput);
//    getTflite().runForMultipleInputsOutputs(mapOfIndicesToOutputs, mapOfIndicesToOutputs);
//
//
//    // Put the backing array in the result that is returned instead of the buffer.
//    mapOfIndicesToOutputs.put(CONFIDENCES_INDEX, confidencesOutput.array());
    return mapOfIndicesToInputs;
  }
}
