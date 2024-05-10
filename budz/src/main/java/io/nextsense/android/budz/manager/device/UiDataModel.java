package io.nextsense.android.budz.manager.device;

import static io.nextsense.android.budz.manager.device.Constants.FOTA_BATTERY_LEVEL_THRESHOLD;
import static io.nextsense.android.budz.manager.device.Constants.FOTA_IS_RUNNING;
import static io.nextsense.android.budz.manager.device.Constants.FOTA_ONLY_OTA_AGENT;
import static io.nextsense.android.budz.manager.device.Constants.KEY_ADAPTIVE_ANC_ACTIVE_RATE;
import static io.nextsense.android.budz.manager.device.Constants.KEY_ADAPTIVE_ANC_COEF_UPDATE_TIME;
import static io.nextsense.android.budz.manager.device.Constants.KEY_ADAPTIVE_ANC_FREEZE_ENGINEER_MODE;
import static io.nextsense.android.budz.manager.device.Constants.KEY_ADAPTIVE_ANC_OPERATION_MODE;
import static io.nextsense.android.budz.manager.device.Constants.KEY_ADAPTIVE_ANC_PASSIVE_RATE;
import static io.nextsense.android.budz.manager.device.Constants.KEY_AMBIENT_CONTROL_ANC_GAIN;
import static io.nextsense.android.budz.manager.device.Constants.KEY_AMBIENT_CONTROL_ANC_INDEX;
import static io.nextsense.android.budz.manager.device.Constants.KEY_AMBIENT_CONTROL_ANC_MODE;
import static io.nextsense.android.budz.manager.device.Constants.KEY_AMBIENT_CONTROL_LAST_FILTER_INDEX;
import static io.nextsense.android.budz.manager.device.Constants.KEY_AMBIENT_CONTROL_PASSTHROUGH_GAIN;
import static io.nextsense.android.budz.manager.device.Constants.KEY_AMBIENT_CONTROL_PASSTHROUGH_INDEX;
import static io.nextsense.android.budz.manager.device.Constants.KEY_AMBIENT_CONTROL_PASSTHROUGH_MODE;
import static io.nextsense.android.budz.manager.device.Constants.KEY_ANC_FILTER_MODE;
import static io.nextsense.android.budz.manager.device.Constants.KEY_AUTO_TEST_L_FOTA_BIN_PATH;
import static io.nextsense.android.budz.manager.device.Constants.KEY_AUTO_TEST_R_FOTA_BIN_PATH;
import static io.nextsense.android.budz.manager.device.Constants.KEY_BDADDRESS;
import static io.nextsense.android.budz.manager.device.Constants.KEY_ENGINEER_MODE;
import static io.nextsense.android.budz.manager.device.Constants.KEY_FEATURE_SET;
import static io.nextsense.android.budz.manager.device.Constants.KEY_PREVIOUS_ADAPTIVE_ANC_ONOFF;

import com.airoha.liblogger.AirohaLogger;
import com.airoha.sdk.api.message.AirohaAncSettings;
import com.airoha.sdk.api.message.AirohaFeatureCapabilities;
import com.airoha.sdk.api.utils.AirohaAncMode;

import java.util.HashMap;

public class UiDataModel {
    private static String TAG = "UiDataModel";
    private static Object gSingletonLock = new Object();
    private static UiDataModel gSingletonInstance;
    private HashMap<String, Object> map;
    AirohaLogger gLogger = AirohaLogger.getInstance();

    private UiDataModel(){
        super();
        map = new HashMap<>();
        //default value
        map.put(KEY_BDADDRESS, "");
        map.put(KEY_ENGINEER_MODE, false);

        map.put(KEY_AMBIENT_CONTROL_LAST_FILTER_INDEX, AirohaAncSettings.UI_ANC_FILTER.ANC1.ordinal());

        map.put(KEY_AMBIENT_CONTROL_ANC_INDEX, AirohaAncSettings.UI_ANC_FILTER.ANC1.ordinal());
        map.put(KEY_AMBIENT_CONTROL_ANC_GAIN, 0);
        map.put(KEY_AMBIENT_CONTROL_ANC_MODE, AirohaAncMode.HYBRID.getValue());
        map.put(KEY_AMBIENT_CONTROL_PASSTHROUGH_INDEX, AirohaAncSettings.UI_ANC_FILTER.VividPassThrough1.ordinal());
        map.put(KEY_AMBIENT_CONTROL_PASSTHROUGH_GAIN, 0);
        map.put(KEY_AMBIENT_CONTROL_PASSTHROUGH_MODE, AirohaAncMode.VIVID_PASSTHROUGH.getValue());
        map.put(KEY_ANC_FILTER_MODE, "");

        map.put(KEY_PREVIOUS_ADAPTIVE_ANC_ONOFF, 0);
        map.put(KEY_ADAPTIVE_ANC_OPERATION_MODE, 1);
        map.put(KEY_ADAPTIVE_ANC_ACTIVE_RATE, 2);
        map.put(KEY_ADAPTIVE_ANC_PASSIVE_RATE, 8);
        map.put(KEY_ADAPTIVE_ANC_FREEZE_ENGINEER_MODE, 0);
        map.put(KEY_ADAPTIVE_ANC_COEF_UPDATE_TIME, 50);

        // FOTA
        map.put(FOTA_IS_RUNNING, false);
        map.put(FOTA_BATTERY_LEVEL_THRESHOLD, 20);
        map.put(FOTA_ONLY_OTA_AGENT, false);
        map.put(KEY_AUTO_TEST_L_FOTA_BIN_PATH, "");
        map.put(KEY_AUTO_TEST_R_FOTA_BIN_PATH, "");

        // featureSet
        map.put(KEY_FEATURE_SET, new AirohaFeatureCapabilities(new byte[] { }));
    }

    public static UiDataModel getInstance(){
        synchronized (gSingletonLock) {
            if (null == gSingletonInstance) {
                gSingletonInstance = new UiDataModel();
            }
        }
        return gSingletonInstance;
    }

    public final Object getParam(String name){
      return map.getOrDefault(name, null);
    }

    public final void setParam(String name, Object ui_data){
        map.remove(name);
        map.put(name, ui_data);
        gLogger.d(TAG, "function = setParam " + name + ":" + ui_data.toString());
    }
}
