package io.nextsense.android.base.devices;

import org.junit.Test;

import static org.junit.Assert.*;

public class NextSenseDeviceManagerTest {

  private final NextSenseDeviceManager deviceManager = new NextSenseDeviceManager();

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
  public void getDeviceForName_h15name_returnsH15Device() {
    assertEquals(H15Device.class, deviceManager.getDeviceForName(H15Device.BLUETOOTH_PREFIX).getClass());
  }

  @Test
  public void getDeviceForName_unknown_returnsNull() {
    assertNull(deviceManager.getDeviceForName("unknown"));
  }
}
