package io.nextsense.android.base.devices;

import org.junit.Test;

import io.nextsense.android.base.data.LocalSessionManager;
import io.nextsense.android.base.db.objectbox.ObjectBoxDatabase;
import io.nextsense.android.base.devices.h1.H1Device;
import io.nextsense.android.base.devices.xenon.XenonDevice;

import static org.junit.Assert.*;

public class NextSenseDeviceManagerTest {

  private final NextSenseDeviceManager deviceManager =
      NextSenseDeviceManager.create(LocalSessionManager.create(new ObjectBoxDatabase(), null));

  @Test
  public void getValidPrefixes_notEmpty() {
    assertFalse(deviceManager.getValidPrefixes().isEmpty());
  }

  @Test
  public void getDeviceForName_h1prefix_returnsH1Device() {
    assertEquals(H1Device.class,
        deviceManager.getDeviceForName(H1Device.BLUETOOTH_PREFIX).getClass());
  }

  @Test
  public void getDeviceForName_h1name_returnsH1Device() {
    assertEquals(H1Device.class,
        deviceManager.getDeviceForName(H1Device.BLUETOOTH_PREFIX + "-1").getClass());
  }

  @Test
  public void getDeviceForName_xenonname_returnsXenonDevice() {
    assertEquals(XenonDevice.class,
        deviceManager.getDeviceForName(XenonDevice.BLUETOOTH_PREFIX).getClass());
  }

  @Test
  public void getDeviceForName_unknown_returnsNull() {
    assertNull(deviceManager.getDeviceForName("unknown"));
  }
}
