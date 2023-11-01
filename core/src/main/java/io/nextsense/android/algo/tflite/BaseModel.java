package io.nextsense.android.algo.tflite;

import android.content.Context;
import android.content.res.AssetFileDescriptor;

import org.tensorflow.lite.Interpreter;

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

    public void loadModel() throws IOException {
        if (tflite != null) {
            RotatingFileLogger.get().logi(TAG, "Model already loaded.");
            return;
        }
        try (AssetFileDescriptor fileDescriptor = context.getAssets().openFd(modelName);
             FileInputStream inputStream =
                 new FileInputStream(fileDescriptor.getFileDescriptor())) {
            FileChannel fileChannel = inputStream.getChannel();
            MappedByteBuffer model = fileChannel.map(FileChannel.MapMode.READ_ONLY,
                fileDescriptor.getStartOffset(), fileDescriptor.getDeclaredLength());
            tflite = new Interpreter(model);
        }
    }

    protected Interpreter getTflite() {
        return tflite;
    }
}
