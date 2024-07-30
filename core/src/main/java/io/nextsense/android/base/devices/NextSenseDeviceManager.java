package io.nextsense.android.base.devices;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;

import io.nextsense.android.base.data.LocalSessionManager;
import io.nextsense.android.base.devices.h1.H1Device;
import io.nextsense.android.base.devices.kauai.KauaiDevice;
import io.nextsense.android.base.devices.kauai_medical.KauaiMedicalDevice;
import io.nextsense.android.base.devices.maui.DataSynchronizer;
import io.nextsense.android.base.devices.maui.MauiDevice;
import io.nextsense.android.base.devices.nitro.NitroDevice;
import io.nextsense.android.base.devices.xenon.XenonDevice;
import io.nextsense.android.base.utils.RotatingFileLogger;

/**
 * Abstracts the different devices that that the mobile application can connect to.
 */
public class NextSenseDeviceManager {

  public enum DeviceGroup {
    CLINICAL,
    CONSUMER
  }

  private static final String TAG = NextSenseDeviceManager.class.getSimpleName();

  // Contains the mapping of devices bluetooth name prefixes to the classes that should be
  // instantiated to
  private final Map<String, Class<? extends NextSenseDevice>> devicesMapping;
  private final LocalSessionManager localSessionManager;
  private DataSynchronizer eegDataSynchronizer;
  private DataSynchronizer imuDataSynchronizer;

  private NextSenseDeviceManager(LocalSessionManager localSessionManager, DeviceGroup deviceGroup) {
    this.localSessionManager = localSessionManager;
    devicesMapping = new HashMap<>();
    if (deviceGroup == null || deviceGroup == DeviceGroup.CLINICAL) {
      devicesMapping.put(H1Device.BLUETOOTH_PREFIX, H1Device.class);
      devicesMapping.put(NitroDevice.BLUETOOTH_PREFIX, NitroDevice.class);
      devicesMapping.put(XenonDevice.BLUETOOTH_PREFIX, XenonDevice.class);
      devicesMapping.put(KauaiDevice.BLUETOOTH_PREFIX, KauaiDevice.class);
      devicesMapping.put(KauaiMedicalDevice.BLUETOOTH_PREFIX, KauaiMedicalDevice.class);
    }
    if (deviceGroup == null || deviceGroup == DeviceGroup.CONSUMER) {
      devicesMapping.put(MauiDevice.BLUETOOTH_PREFIX_LEFT, MauiDevice.class);
      devicesMapping.put(MauiDevice.BLUETOOTH_PREFIX_RIGHT, MauiDevice.class);
    }
  }

  public static NextSenseDeviceManager create(
      LocalSessionManager localSessionManager, DeviceGroup deviceGroup) {
    return new NextSenseDeviceManager(localSessionManager, deviceGroup);
  }


  public static NextSenseDeviceManager create(LocalSessionManager localSessionManager) {
    return new NextSenseDeviceManager(localSessionManager, DeviceGroup.CLINICAL);
  }

  public Set<String> getValidPrefixes() {
    return devicesMapping.keySet();
  }

  public NextSenseDevice getDeviceForName(String name) {
    Class<? extends NextSenseDevice> deviceClass = null;
    for (String prefix : getValidPrefixes()) {
      if (name.startsWith(prefix)) {
        deviceClass = devicesMapping.get(prefix);
        break;
      }
    }
    if (deviceClass == null) {
      RotatingFileLogger.get().logw(TAG, "Could not find a device for " + name);
      return null;
    }
    try {
      NextSenseDevice nextSenseDevice = deviceClass.newInstance();
      nextSenseDevice.setLocalSessionManager(localSessionManager);
      if (nextSenseDevice instanceof MauiDevice) {
        if (eegDataSynchronizer == null) {
          eegDataSynchronizer = new DataSynchronizer(nextSenseDevice.getEegChannelNames(), 1000);
        }
        if (imuDataSynchronizer == null) {
          imuDataSynchronizer = new DataSynchronizer(nextSenseDevice.GetAccChannelNames(), 100);
        }
        ((MauiDevice) nextSenseDevice).setDataSynchronizers(
            eegDataSynchronizer, imuDataSynchronizer);
      }
      return nextSenseDevice;
    } catch (IllegalAccessException | InstantiationException e) {
      RotatingFileLogger.get().loge(TAG, "Could not instantiate " + deviceClass.getName());
      return null;
    }
  }
}
