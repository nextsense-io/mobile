package io.nextsense.android.base.communication.firebase;

import android.util.Base64;
import android.util.Log;

import androidx.annotation.Nullable;

import com.google.android.gms.tasks.Task;
import com.google.android.gms.tasks.Tasks;
import com.google.firebase.functions.FirebaseFunctions;

import java.io.ByteArrayOutputStream;
import java.time.Duration;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

import io.nextsense.android.base.utils.Util;

/**
 * Firebase functions interface.
 */
public class CloudFunctions {
    private static final String TAG = CloudFunctions.class.getSimpleName();
    private static final String UPLOAD_FUNCTION_NAME = "enqueue_upload_data_samples_test";
    private static final String UPLOAD_FUNCTION_DISPLAY_NAME = "enqueue upload data samples";
    private static final Duration UPLOAD_FUNCTION_TIMEOUT = Duration.ofMillis(10000);
    private static final String COMPLETE_SESSION_FUNCTION_NAME = "enqueue_complete_session";
    private static final String COMPLETE_SESSION_FUNCTION_DISPLAY_NAME = "enqueue complete session";
    private static final Duration COMPLETE_SESSION_FUNCTION_TIMEOUT = null;
    private static final String DATA_SAMPLES_PARAM_NAME = "data_samples_proto";
    private static final String SESSION_PARAM_NAME = "session_proto";

    private final FirebaseFunctions functionsInstance = FirebaseFunctions.getInstance();

    // TODO(eric): Authenticate the request:
    // https://cloud.google.com/functions/docs/securing/authenticating#functions-bearer-token-example-java
    public static CloudFunctions create() {
        return new CloudFunctions();
    }

    public boolean uploadDataSamples(ByteArrayOutputStream data) {
        return runTask(data, UPLOAD_FUNCTION_NAME, UPLOAD_FUNCTION_TIMEOUT, DATA_SAMPLES_PARAM_NAME,
                UPLOAD_FUNCTION_DISPLAY_NAME);
    }

    public boolean completeSession(ByteArrayOutputStream data) {
        return runTask(data, COMPLETE_SESSION_FUNCTION_NAME, COMPLETE_SESSION_FUNCTION_TIMEOUT,
                SESSION_PARAM_NAME, COMPLETE_SESSION_FUNCTION_DISPLAY_NAME);
    }

    private Task<Map<String, Object>> runFunction(
            Map<String, Object> data, String functionName, String functionDisplayName) {
        return functionsInstance
                .getHttpsCallable(functionName)
                .call(data)
                .addOnFailureListener(exception -> Log.e(TAG, "Failed to " +
                        functionDisplayName + ": " + exception.getMessage()))
                .continueWith(task -> {
                    // This continuation runs on either success or failure, but if the task has
                    // failed then getResult() will throw an Exception which will be propagated
                    // down.
                    if (task.getResult() != null) {
                        @SuppressWarnings("unchecked")
                        Map<String, Object> result =
                                (Map<String, Object>) task.getResult().getData();
                        Util.logd(TAG, functionDisplayName + " result: " + result);
                        return result;
                    }
                    return new HashMap<>();
                });
    }

    private boolean runTask(
            ByteArrayOutputStream dataOutputStream, String functionName, @Nullable Duration timeout,
            String dataParamName, String functionDisplayName) {
        boolean success = false;
        try {
            Map<String, Object> data = new HashMap<>();
            data.put(dataParamName,
                    Base64.encodeToString(dataOutputStream.toByteArray(), Base64.DEFAULT));
            // Block on the task until successful or the timeout duration is reached, then time out.
            Task<Map<String, Object>> task = runFunction(data, functionName, functionDisplayName);
            if (timeout != null) {
                Map<String, Object> uploadResult =
                        Tasks.await(task, timeout.toMillis(), TimeUnit.MILLISECONDS);
                Util.logd(TAG, functionDisplayName + " result: " + uploadResult.get("result"));
            }
            success = true;
        } catch (ExecutionException | TimeoutException e) {
            Log.e(TAG, "Failed to " + functionDisplayName + ": " + e.getMessage(), e);
        } catch (InterruptedException e) {
            Log.e(TAG, "Failed to" + functionDisplayName + ": " + e.getMessage(), e);
            Thread.currentThread().interrupt();
        }
        return success;
    }
}
