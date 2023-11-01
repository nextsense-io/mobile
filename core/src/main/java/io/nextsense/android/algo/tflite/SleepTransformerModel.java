package io.nextsense.android.algo.tflite;

import android.content.Context;

import java.nio.FloatBuffer;
import java.time.Duration;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.nextsense.android.base.utils.RotatingFileLogger;

public class SleepTransformerModel extends BaseModel {

  public static final Duration EPOCH_LENGTH = Duration.ofSeconds(30);
  public static final int MAX_INPUT_EPOCHS = 21;
  public static final int RESULTS_INDEX = 0;
  public static final int CONFIDENCES_INDEX = 1;
  private static final String TAG = SleepTransformerModel.class.getSimpleName();
  private static final String MODEL_NAME = "sleep_stage_classifier.tflite";

  public SleepTransformerModel(Context context) {
    super(context, MODEL_NAME);
  }

  public Map<Integer, Object> doInference(List<Float> data, float samplingRate) {
    int numEpochs = (int)Math.round(Math.floor(
        (data.size() / samplingRate) / (int) EPOCH_LENGTH.getSeconds()));
    if (numEpochs > MAX_INPUT_EPOCHS) {
      RotatingFileLogger.get().logw(TAG,
          "Input data is too long. Max input length is " + MAX_INPUT_EPOCHS + " epochs." +
          "Ignoring the rest of the data.");
      numEpochs = MAX_INPUT_EPOCHS;
    }
    // TODO(eric): Remove test data definition.
    numEpochs = 134;
    float[][] testData = new float[1][1000000];
    for (int i = 0; i < 1000000; i++) {
      testData[0][i] = 0.0f;
    }
    Map<Integer, Object> mapOfIndicesToOutputs = new HashMap<>();
    String[] resultsOutput = new String[numEpochs];
    mapOfIndicesToOutputs.put(RESULTS_INDEX, resultsOutput);
    FloatBuffer confidencesOutput = FloatBuffer.allocate(numEpochs);
    mapOfIndicesToOutputs.put(CONFIDENCES_INDEX, confidencesOutput);
    // getTflite().runForMultipleInputsOutputs(data.toArray(), mapOfIndicesToOutputs);
    getTflite().runForMultipleInputsOutputs(testData, mapOfIndicesToOutputs);
    // Put the backing array in the result that is returned instead of the buffer.
    mapOfIndicesToOutputs.put(CONFIDENCES_INDEX, confidencesOutput.array());
    return mapOfIndicesToOutputs;
  }
}
