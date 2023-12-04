package io.nextsense.android;

public class ApplicationTypeHelper {
  private static final String FLAVOR_CONSUMER = "consumer";
  private static final String FLAVOR_LUCID = "lucid";

  public static ApplicationType getApplicationType(String flavor) {
    if (flavor.contains(FLAVOR_CONSUMER)) {
      return ApplicationType.CONSUMER;
    } else if (flavor.contains(FLAVOR_LUCID)) {
      return ApplicationType.LUCID_REALITY;
    } else {
      return ApplicationType.MEDICAL;
    }
  }
}