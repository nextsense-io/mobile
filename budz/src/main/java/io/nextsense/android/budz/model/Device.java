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

package io.nextsense.android.budz.model;

import android.os.Parcel;
import android.os.Parcelable;

import java.io.Serializable;

public class Device implements Parcelable, Serializable {

    // this is used to regenerate your object. All Parcelables must have a CREATOR that implements these two methods
    public static final Creator<Device> CREATOR = new Creator<Device>() {
        public Device createFromParcel(Parcel in) {
            return new Device(in);
        }

        public Device[] newArray(int size) {
            return new Device[size];
        }
    };
    private String deviceId = "";
    private String deviceName;
    private String deviceAddress;
    private int batteryLeft = 0;
    private int batteryRight = 0;
    private int batteryCase = 0;
    private String versionLeft = "-";
    //private DeviceConnectionType connectionType = DeviceConnectionType.Disconnected;
    private String versionRight = "-";

    public Device(String name, String address) {
        this.deviceName = name;
        this.deviceAddress = address;
    }

    // example constructor that takes a Parcel and gives you an object populated with it's values
    private Device(Parcel in) {
        deviceId = in.readString();
        deviceName = in.readString();
        deviceAddress = in.readString();
        batteryLeft = in.readInt();
        batteryRight = in.readInt();
        batteryCase = in.readInt();
        versionLeft = in.readString();
        versionRight = in.readString();
        //connectionType = DeviceConnectionType.getType(in.readInt());
    }

    public final String getDeviceName() {
        return deviceName;
    }

    public final void setDeviceName(String deviceName) {
        this.deviceName = deviceName;
    }

    public final String getDeviceAddress() {
        return deviceAddress;
    }

    public final void setDeviceAddress(String deviceAddress) {
        this.deviceAddress = deviceAddress;
    }

    public final int getBatteryLeft() {
        return batteryLeft;
    }

    public final void setBatteryLeft(int batteryLeft) {
        this.batteryLeft = batteryLeft;
    }

    public final int getBatteryRight() {
        return batteryRight;
    }

    public final void setBatteryRight(int batteryRight) {
        this.batteryRight = batteryRight;
    }

    public final int getBatteryCase() {
        return batteryCase;
    }

    public final void setBatteryCase(int batteryCase) {
        this.batteryCase = batteryCase;
    }

    public final String getVersionLeft() {
        return versionLeft;
    }

    public final void setVersionLeft(String versionLeft) {
        this.versionLeft = versionLeft;
    }

    public final String getVersionRight() {
        return versionRight;
    }

    public final void setVersionRight(String versionRight) {
        this.versionRight = versionRight;
    }

    public final String getDeviceId() {
        return deviceId;
    }

    public final void setDeviceId(String deviceId) {
        this.deviceId = deviceId;
    }

    @Override
    public final int describeContents() {
        return 0;
    }

    @Override
    public final void writeToParcel(Parcel parcel, int i) {
        parcel.writeString(deviceId);
        parcel.writeString(deviceName);
        parcel.writeString(deviceAddress);
        parcel.writeInt(batteryLeft);
        parcel.writeInt(batteryRight);
        parcel.writeInt(batteryCase);
        parcel.writeString(versionLeft);
        parcel.writeString(versionRight);
        //parcel.writeInt(connectionType.getValue());
    }

    private void readObject(java.io.ObjectInputStream in) throws java.io.IOException, ClassNotFoundException {
        throw new java.io.NotSerializableException("io.nextsense.android.budz.model.Device");
    }

    private void writeObject(java.io.ObjectOutputStream out) throws java.io.IOException {
        throw new java.io.NotSerializableException("io.nextsense.android.budz.model.Device");
    }
}
