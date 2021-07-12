package io.nextsense.android.base.devices;

import android.util.Log;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;

/**
 * Abstracts the different devices that that the mobile application can connect to.
 */
public class NextSenseDeviceManager {

  private static final String TAG = NextSenseDeviceManager.class.getSimpleName();

  // Contains the mapping of devices bluetooth name prefixes to the classes that should be
  // instantiated to
  private final Map<String, Class<? extends NextSenseDevice>> devicesMapping;

  public NextSenseDeviceManager() {
    devicesMapping = new HashMap<>();
    devicesMapping.put(H1Device.BLUETOOTH_PREFIX, H1Device.class);
    devicesMapping.put(H15Device.BLUETOOTH_PREFIX, H15Device.class);
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
      Log.w(TAG, "Could not find a device for " + name);
      return null;
    }
    try {
      return deviceClass.newInstance();
    } catch (IllegalAccessException | InstantiationException e) {
      Log.e(TAG, "Could not instantiate " + deviceClass.getName());
      return null;
    }
  }
}
