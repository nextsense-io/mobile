package io.nextsense.android;

public class Config {

    private Config() {}

    // This should be changed also in Config.dart
    public static final boolean USE_EMULATED_BLE = false;

    // Name of the https time series upload function in Firebase.
    public static final String UPLOAD_FUNCTION_NAME = "enqueue_upload_data_samples";

    // Name of the https session complete function in Firebase.
    public static final String COMPLETE_SESSION_FUNCTION_NAME = "enqueue_complete_session";
}
