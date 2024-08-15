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

package io.nextsense.android.airoha.device;

import android.annotation.SuppressLint;
import android.bluetooth.BluetoothA2dp;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.bluetooth.BluetoothProfile;
import android.content.Context;
import android.os.ParcelUuid;
import android.util.Log;

import com.airoha.liblogger.AirohaLogger;
import com.airoha.libutils.Converter;
import com.airoha.sdk.AirohaConnector;
import com.airoha.sdk.AirohaSDK;
import com.airoha.sdk.api.device.AirohaDevice;
import com.airoha.sdk.api.message.AirohaBaseMsg;
import com.airoha.sdk.api.utils.ConnectionProtocol;
import com.airoha.sdk.api.utils.ConnectionUUID;

import java.util.Set;
import java.util.UUID;

@SuppressLint("MissingPermission")
public class DeviceSearchPresenter implements AirohaConnector.AirohaConnectionListener {

    private static final String TAG = "DeviceSearchPresenter";
    public static final String KEY_BDADDRESS = "KEY_BDADDRESS";
    private static final AirohaLogger gLogger = AirohaLogger.getInstance();
    private final Context act;

    private static final String SPP_UUID = "00000000-0000-0000-0099-AABBCCDDEEFF";
    private boolean _isConnected = false;
    private final AirohaConnector _airohaDeviceConnector;
    private boolean _isChecking;
    private Thread _thread;

    private final BluetoothAdapter mBluetoothAdapter;
    private final A2DPProfileServiceListener mA2dpProfileServiceListener;
    private BluetoothA2dp mBluetoothProfileA2DP = null;

    public DeviceSearchPresenter(Context context) {
        act = context;
        _airohaDeviceConnector = AirohaSDK.getInst().getAirohaDeviceConnector();
        _airohaDeviceConnector.registerConnectionListener(this);

        final BluetoothManager bluetoothManager = (BluetoothManager) act.getSystemService(Context.BLUETOOTH_SERVICE);
        mBluetoothAdapter = bluetoothManager.getAdapter();
        mA2dpProfileServiceListener = new A2DPProfileServiceListener();
        mBluetoothAdapter.getProfileProxy(act, mA2dpProfileServiceListener, BluetoothProfile.A2DP);
        Log.i(TAG, "initialized");
    }

    public final void destroy() {
        AirohaConnector airohaDeviceConnector = AirohaSDK.getInst().getAirohaDeviceConnector();
        airohaDeviceConnector.unregisterConnectionListener(this);
        stopConnectingBoundDevice();
    }

    /**
     * Connect to the bound device.
     *
     * @return true if already connected. Otherwise, return false.
     */
    public final boolean connectBoundDevice() {
        gLogger.d(TAG, "connectBoundDevice()");

        if (_isConnected) {
            gLogger.d(TAG, "already_connected");
            return true;
        }

        try {
            _isChecking = false;
            if (_thread != null) {
                gLogger.d(TAG, "connectBoundDevice().interrupt");
                _thread.interrupt();
                _thread.join(1000);
            }
        } catch (Exception ex) {
            gLogger.e(ex);
        }

        _isChecking = true;
        _thread = new Thread(this::checkBondDevice);
        _thread.start();
        return false;
    }

    public void stopConnectingBoundDevice() {
        _isChecking = false;
        if (_thread != null) {
            _thread.interrupt();
        }
        _thread = null;
    }

    final void checkBondDevice() {
        if (_isConnected) {
            return;
        }

        try {
            int i = 0;
            while (_isChecking) {
                i++;
                gLogger.d(TAG, "checkBondDevice_seq=" + i);
                findConnectedDevice();
                Thread.sleep(500);
            }
        } catch (InterruptedException ignored) {
        } catch (Exception ex) {
            gLogger.e(ex);
        }
    }

    final boolean isAirohaDevice(BluetoothDevice device) {
        ParcelUuid[] pus = device.getUuids();
        if (pus == null) {
            return false;
        }

        for (ParcelUuid pu : pus) {
            String reversed_uuid = Converter.byte2HerStrReverse(Converter.hexStrToBytes(pu.getUuid().toString().replace("-", ""))).replace(" ","");
            gLogger.d(TAG, "variable = reversed_uuid: " + reversed_uuid);
            gLogger.d(TAG, "variable = uuid: " + pu.getUuid().toString());
            if (pu.getUuid().toString().equalsIgnoreCase(SPP_UUID) || reversed_uuid.equalsIgnoreCase(SPP_UUID.replace("-",""))) {

                return true;
            }
        }
        return false;
    }

    private void findConnectedDevice() {
        BluetoothAdapter adapter = BluetoothAdapter.getDefaultAdapter();
        try {
            if (!adapter.isEnabled()) {
                Log.i(TAG, "adapter.isEnabled()=" + adapter.isEnabled());
                return;
            }

            if (adapter.getState() != BluetoothAdapter.STATE_ON) {
                Log.i(TAG, "adapter.getState()=" + adapter.getState());
                return;
            }

            Set<BluetoothDevice> devices = adapter.getBondedDevices();

            Log.i(TAG, "devices.size()=====================" + devices.size());

            for (BluetoothDevice device : devices) {
                Log.i(TAG, "found_device==================" + device.getName() + "," + device.getAddress());
            }

            for (BluetoothDevice device : devices) {
                if (isA2dpConnected(device.getAddress()) && isAirohaDevice(device)) {
                    Log.i(TAG, "device_airoha==================" + device.getName() + "," + device.getAddress());
                    Log.i(TAG, "device_A2DP_connected==================" + device.getName() + "," + device.getAddress());
                    connectClassicDevice(device);

                    synchronized (this) {
                        wait(30 * 1000);
                    }
                }

                if (_isConnected) {
                    gLogger.d(TAG, "connected_and_stop_loop");
                    _isChecking = false;
                    break;
                }
            }
        } catch (Exception ex) {
            gLogger.e(ex);
        }
    }

    public boolean findAirohaDevice() {
        BluetoothAdapter adapter = BluetoothAdapter.getDefaultAdapter();
        try {
            if (!adapter.isEnabled()) {
                Log.i(TAG, "adapter.isEnabled()=" + adapter.isEnabled());
                return false;
            }

            if (adapter.getState() != BluetoothAdapter.STATE_ON) {
                Log.i(TAG, "adapter.getState()=" + adapter.getState());
                return false;
            }

            Set<BluetoothDevice> devices = adapter.getBondedDevices();

            Log.i(TAG, "devices.size()=====================" + devices.size());

            for (BluetoothDevice device : devices) {
                Log.i(TAG, "found_device==================" + device.getName() + "," + device.getAddress());
            }

            for (BluetoothDevice device : devices) {
                if (isA2dpConnected(device.getAddress()) && isAirohaDevice(device)) {
                    Log.i(TAG, "device_airoha==================" + device.getName() + "," + device.getAddress());
                    Log.i(TAG, "device_A2DP_connected==================" + device.getName() + "," + device.getAddress());
                    return true;
                }
            }
        } catch (Exception ex) {
            gLogger.e(ex);
        }
        return false;
    }

    final void connectClassicDevice(BluetoothDevice airoha_device) {
        AirohaDevice airohaDevice = new AirohaDevice();
        airohaDevice.setApiStrategy(new BudzDeviceStrategy());
        airohaDevice.setTargetAddr(airoha_device.getAddress());
        airohaDevice.setDeviceName(airoha_device.getName());
        airohaDevice.setPreferredProtocol(ConnectionProtocol.PROTOCOL_SPP);

        ConnectionUUID connectionUUID = new ConnectionUUID(UUID.fromString(SPP_UUID));
        _airohaDeviceConnector.connect(airohaDevice, connectionUUID);

//        BudzApplication.Companion.getInstance().initDevice(
//            airoha_device.getName(), airoha_device.getAddress());
    }

    @Override
    public final void onStatusChanged(int status) {
        gLogger.d(TAG, "onStatusChanged=" + status);

        String text = "";
        if (status == AirohaConnector.CONNECTION_STATUS_BASE) text = "CONNECTION_STATUS_BASE";
        else if (status == AirohaConnector.WAITING_CONNECTABLE) text = "WAITING_CONNECTABLE";
        else if (status == AirohaConnector.CONNECTING) text = "CONNECTING";
        else if (status == AirohaConnector.CONNECTED) text = "CONNECTED";
        else if (status == AirohaConnector.DISCONNECTING) text = "DISCONNECTING";
        else if (status == AirohaConnector.DISCONNECTED) text = "DISCONNECTED";
        else if (status == AirohaConnector.CONNECTION_ERROR) text = "CONNECTION_ERROR";
        else if (status == AirohaConnector.INITIALIZATION_FAILED) text = "INITIALIZATION_FAILED";
        else if (status == AirohaConnector.CONNECTED_WRONG_ROLE) text = "CONNECTED_WRONG_ROLE";
        gLogger.d(TAG, "onStatusChanged=" + text);

        if (status == AirohaConnector.CONNECTED) {
            _isConnected = true;
            AirohaDataModel.getInstance().setParam(KEY_BDADDRESS, _airohaDeviceConnector.getDevice().getTargetAddr());
        }
        else if (status == AirohaConnector.DISCONNECTED) {
            _isConnected = false;
            AirohaDataModel.getInstance().setParam(KEY_BDADDRESS, "");
        }

        if (status == AirohaConnector.CONNECTING ||
                status == AirohaConnector.CONNECTED_WRONG_ROLE ||
                status == AirohaConnector.DISCONNECTING ) {
            return;
        }
        synchronized (this) {
            gLogger.d(TAG, "_isConnected=" + _isConnected);
            notify();
        }
    }

    @Override
    public final void onDataReceived(AirohaBaseMsg airohaBaseMsg) {
        if (airohaBaseMsg == null) {
            gLogger.d(TAG, "onDataReceived");
            return;
        }

        if (airohaBaseMsg.getMsgID() != null) {
            gLogger.d(TAG, "onDataReceived=" + airohaBaseMsg.getMsgID().getCmdName());
        }

        if (airohaBaseMsg.getMsgContent() != null) {
            gLogger.d(TAG, "onDataReceived=" + "," + airohaBaseMsg.getMsgContent().getClass().getName() + "," + airohaBaseMsg.getMsgContent().toString());
        }
    }


    public class A2DPProfileServiceListener implements BluetoothProfile.ServiceListener {
        @Override
        public void onServiceConnected(int profile, BluetoothProfile bluetoothProfile) {
            if (profile == BluetoothProfile.A2DP) {
                mBluetoothProfileA2DP = (BluetoothA2dp) bluetoothProfile;
            }
        }

        @Override
        public void onServiceDisconnected(int profile) {
            if(profile == BluetoothProfile.A2DP){
                mBluetoothProfileA2DP = null;
            }
        }
    }

    @SuppressWarnings({"MissingPermission"})
    private boolean isA2dpConnected(String bdAddr) {
        if (mBluetoothProfileA2DP == null) {
            mBluetoothAdapter.getProfileProxy(act, mA2dpProfileServiceListener, BluetoothProfile.A2DP);
            gLogger.d(TAG, "Error = mBluetoothProfileA2DP is null");
            return false;
        }
        BluetoothDevice device = mBluetoothAdapter.getRemoteDevice(bdAddr);
        if (mBluetoothProfileA2DP.getConnectionState(device) == BluetoothProfile.STATE_CONNECTED) {
            return true;
        } else {
            gLogger.d(TAG, "Error = A2DP is not Connected: " + bdAddr);
            return false;
        }
    }
}
