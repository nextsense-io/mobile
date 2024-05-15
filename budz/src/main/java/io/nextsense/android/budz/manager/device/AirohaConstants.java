/* Copyright Statement:
 *
 * (C) 2022  Airoha Technology Corp. All rights reserved.
 *
 * This software/firmware and related documentation ("Airoha Software") are
 * protected under relevant copyright laws. The information contained herein
 * is confidential and proprietary to Airoha Technology Corp. ("Airoha") and/or its licensors.
 * Without the prior written permission of Airoha and/or its licensors,
 * any reproduction, modification, use or disclosure of Airoha Software,
 * and information contained herein, in whole or in part, shall be strictly prohibited.
 * You may only use, reproduce, modify, or distribute (as applicable) Airoha Software
 * if you have agreed to and been bound by the applicable license agreement with
 * Airoha ("License Agreement") and been granted explicit permission to do so within
 * the License Agreement ("Permitted User").  If you are not a Permitted User,
 * please cease any access or use of Airoha Software immediately.
 * BY OPENING THIS FILE, RECEIVER HEREBY UNEQUIVOCALLY ACKNOWLEDGES AND AGREES
 * THAT AIROHA SOFTWARE RECEIVED FROM AIROHA AND/OR ITS REPRESENTATIVES
 * ARE PROVIDED TO RECEIVER ON AN "AS-IS" BASIS ONLY. AIROHA EXPRESSLY DISCLAIMS ANY AND ALL
 * WARRANTIES, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR NONINFRINGEMENT.
 * NEITHER DOES AIROHA PROVIDE ANY WARRANTY WHATSOEVER WITH RESPECT TO THE
 * SOFTWARE OF ANY THIRD PARTY WHICH MAY BE USED BY, INCORPORATED IN, OR
 * SUPPLIED WITH AIROHA SOFTWARE, AND RECEIVER AGREES TO LOOK ONLY TO SUCH
 * THIRD PARTY FOR ANY WARRANTY CLAIM RELATING THERETO. RECEIVER EXPRESSLY ACKNOWLEDGES
 * THAT IT IS RECEIVER'S SOLE RESPONSIBILITY TO OBTAIN FROM ANY THIRD PARTY ALL PROPER LICENSES
 * CONTAINED IN AIROHA SOFTWARE. AIROHA SHALL ALSO NOT BE RESPONSIBLE FOR ANY AIROHA
 * SOFTWARE RELEASES MADE TO RECEIVER'S SPECIFICATION OR TO CONFORM TO A PARTICULAR
 * STANDARD OR OPEN FORUM. RECEIVER'S SOLE AND EXCLUSIVE REMEDY AND AIROHA'S ENTIRE AND
 * CUMULATIVE LIABILITY WITH RESPECT TO AIROHA SOFTWARE RELEASED HEREUNDER WILL BE,
 * AT AIROHA'S OPTION, TO REVISE OR REPLACE AIROHA SOFTWARE AT ISSUE,
 * OR REFUND ANY SOFTWARE LICENSE FEES OR SERVICE CHARGE PAID BY RECEIVER TO
 * AIROHA FOR SUCH AIROHA SOFTWARE AT ISSUE.
 */
/* Airoha restricted information */

package io.nextsense.android.budz.manager.device;

public class AirohaConstants {

    private AirohaConstants() {}

    public static final String KEY_DEVICE_INFO = "key_device_info";
    public static final String KEY_HEARING_TEST_SIDE = "key_hearing_test_side";

    public static final String KEY_DEVICE_NAME = "key_device_name";
    public static final String KEY_DEVICE_UUID = "key_device_uuid";

    public static final String KEY_IS_FROM_LOGIN = "key_is_from_login";
    public static final String KEY_AUDIOGRAM_TYPE = "key_audiogram_type";
    public static final String KEY_APP_SHARED_PREFERENCE = "com.audiowise.earbuds.hearclarity";
    public static final String KEY_APPLY_AUDIOGRAM = "key_apply_audiogram";
    public static final String KEY_TRANSPARENCY_BALANCE = "key_transparency_balance";
    public static final String KEY_SURROUND_SOUND_OPTION = "key_surround_sound_option";
    public static final String KEY_SELECTED_HEARING_TEST_TYPE = "key_selected_hearing_test_type";
    public static final String KEY_LEFT_TEST_RESULT = "key_left_test_result";
    public static final String KEY_IS_LOGGED_IN = "key_is_logged_in";
    public static final String KEY_IS_DEVICE_LIST_EMPTY = "key_is_device_list_empty";
    public static final String KEY_HT_IS_ON = "key_ht_is_on";
    public static final String KEY_TEST_DATE = "key_test_date";
    public static final String KEY_HA_SCENE_MODE = "key_ha_scene_mode";
    public static final String KEY_HA_SCENE_MODE_NAME = "key_ha_scene_mode_name";
    public static final String KEY_NOISE_REDUCTION_INDOOR = "key_noise_reduction_indoor";
    public static final String KEY_NOISE_REDUCTION_OUTDOOR = "key_noise_reduction_outdoor";
    public static final String KEY_NOISE_REDUCTION_TRANSPORTATION = "key_noise_reduction_transportation";
    public static final String KEY_NOISE_REDUCTION_SOCIAL = "key_noise_reduction_social";
    public static final String KEY_FROM_FIRMWARE_UPDATE = "key_from_firmware_update";

    public static final String KEY_NETWORK_SHARED_PREFERENCE = "com.audiowise.network";


    // for UI Data Model
    public static final String KEY_BDADDRESS = "KEY_BDADDRESS";

    public static final String KEY_ENGINEER_MODE = "KEY_ENGINEER_MODE";

    public static final String KEY_AMBIENT_CONTROL_LAST_FILTER_INDEX = "KEY_AMBIENT_CONTROL_LAST_FILTER_INDEX";
    public static final String KEY_AMBIENT_CONTROL_ANC_INDEX = "KEY_AMBIENT_CONTROL_ANC_INDEX";
    public static final String KEY_AMBIENT_CONTROL_ANC_GAIN = "KEY_AMBIENT_CONTROL_ANC_GAIN";
    public static final String KEY_AMBIENT_CONTROL_ANC_MODE = "KEY_AMBIENT_CONTROL_ANC_MODE";
    public static final String KEY_AMBIENT_CONTROL_PASSTHROUGH_INDEX = "KEY_AMBIENT_CONTROL_PASSTHROUGH_INDEX";
    public static final String KEY_AMBIENT_CONTROL_PASSTHROUGH_GAIN = "KEY_AMBIENT_CONTROL_PASSTHROUGH_GAIN";
    public static final String KEY_AMBIENT_CONTROL_PASSTHROUGH_MODE = "KEY_AMBIENT_CONTROL_PASSTHROUGH_MODE";
    public static final String KEY_ANC_FILTER_MODE = "KEY_ANC_FILTER_MODE";

    public static final String KEY_PREVIOUS_ADAPTIVE_ANC_ONOFF = "KEY_PREVIOUS_ADAPTIVE_ANC_ONOFF";
    public static final String KEY_ADAPTIVE_ANC_OPERATION_MODE = "KEY_ADAPTIVE_ANC_OPERATION_MODE";
    public static final String KEY_ADAPTIVE_ANC_ACTIVE_RATE = "KEY_ADAPTIVE_ANC_ACTIVE_RATE";
    public static final String KEY_ADAPTIVE_ANC_PASSIVE_RATE = "KEY_ADAPTIVE_ANC_PASSIVE_RATE";
    public static final String KEY_ADAPTIVE_ANC_COEF_UPDATE_TIME = "KEY_ADAPTIVE_ANC_COEF_UPDATE_TIME";
    public static final String KEY_ADAPTIVE_ANC_FREEZE_ENGINEER_MODE = "KEY_ADAPTIVE_ANC_FREEZE_ENGINEER_MODE";

    public static final String KEY_ENVIRONMENT_DETECTION_STATUS = "KEY_ENVIRONMENT_DETECTION_STATUS";
    public static final String KEY_WIND_DETECTION_STATUS = "KEY_WIND_DETECTION_STATUS";

    public static final String KEY_AURACAST_DEVICE_MODEL = "KEY_AURACAST_DEVICE_MODEL";

    public static final String FOTA_IS_RUNNING = "FOTA_IS_RUNNING";
    public static final String FOTA_BATTERY_LEVEL_THRESHOLD = "FOTA_BATTERY_LEVEL_THRESHOLD";
    public static final String FOTA_ONLY_OTA_AGENT = "FOTA_ONLY_OTA_AGENT";
    public static final String COMMIT_IS_RUNNING = "COMMIT_IS_RUNNING";

    public static final String ONLINE_LOG_IS_RUNNING = "ONLINE_LOG_IS_RUNNING";
    public static final String ONLINE_LOG_FILE_PATH = "ONLINE_LOG_FILE_PATH";
    public static final String TWO_MIC_DUMP_IS_RUNNING = "TWO_MIC_DUMP_IS_RUNNING";

    public static final String KEY_FEATURE_SET = "KEY_FEATURE_SET";
    public static final int[] PSAP_FREQS = new int[]{0, 250, 500, 1000, 1500, 2000,
            2500, 3000, 4000, 6000, 8000, 10000};

    public static final String KEY_AUTO_TEST_L_FOTA_BIN_PATH = "KEY_AUTO_TEST_L_FOTA_BIN_PATH";
    public static final String KEY_AUTO_TEST_R_FOTA_BIN_PATH = "KEY_AUTO_TEST_R_FOTA_BIN_PATH";
    public static final String EXTRA_KEY_AUTO_TEST_L_FOTA_BIN_PATH = "L_FotaBinPath";
    public static final String EXTRA_KEY_AUTO_TEST_R_FOTA_BIN_PATH = "R_FotaBinPath";
}