package io.nextsense.android.algo.tflite;

import android.content.Context;
import android.content.res.AssetFileDescriptor;

import org.tensorflow.lite.Interpreter;
import org.tensorflow.lite.gpu.CompatibilityList;
import org.tensorflow.lite.gpu.GpuDelegate;

import java.io.FileInputStream;
import java.io.IOException;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;

import io.nextsense.android.base.utils.RotatingFileLogger;

public abstract class BaseModel {
    private static final String TAG = BaseModel.class.getSimpleName();

    private Context context;
    private String modelName;
    private Interpreter tflite;

    protected BaseModel(Context context, String modelName) {
        this.context = context;
        this.modelName = modelName;
    }

    protected Interpreter loadModelAsset(String modelAssetPath, boolean useGpu) throws IOException {
        // Initialize interpreter with GPU delegate
        Interpreter.Options options = new Interpreter.Options();
        CompatibilityList compatList = new CompatibilityList();

        if (useGpu && compatList.isDelegateSupportedOnThisDevice()) {
            // if the device has a supported GPU, add the GPU delegate
            GpuDelegate.Options delegateOptions = compatList.getBestOptionsForThisDevice();
            GpuDelegate gpuDelegate = new GpuDelegate(delegateOptions);
            options.addDelegate(gpuDelegate);
        } else {
            // if the GPU is not supported, run on 4 threads
            options.setNumThreads(4);
        }

        try (AssetFileDescriptor fileDescriptor = context.getAssets().openFd(modelAssetPath);
             FileInputStream inputStream =
                 new FileInputStream(fileDescriptor.getFileDescriptor())) {
            FileChannel fileChannel = inputStream.getChannel();
            MappedByteBuffer model = fileChannel.map(FileChannel.MapMode.READ_ONLY,
                fileDescriptor.getStartOffset(), fileDescriptor.getDeclaredLength());
            return new Interpreter(model, options);
        }
    }

    public void loadModel(boolean useGpu) throws IOException {
        if (tflite != null) {
            RotatingFileLogger.get().logi(TAG, "Model already loaded.");
            return;
        }
        tflite = loadModelAsset(modelName, useGpu);
    }

    public void closeModel() {
        if (tflite != null) {
            tflite.close();
            tflite = null;
        }
    }

    protected Interpreter getTflite() {
        return tflite;
    }
}
