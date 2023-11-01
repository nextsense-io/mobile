package io.nextsense.android;

public class ApplicationTypeHelper {
  private static final String FLAVOR_CONSUMER = "consumer";
  public static ApplicationType getApplicationType(String flavor) {
    if (flavor.contains(FLAVOR_CONSUMER)) {
      return ApplicationType.CONSUMER;
    } else {
      return ApplicationType.MEDICAL;
    }
  }
}