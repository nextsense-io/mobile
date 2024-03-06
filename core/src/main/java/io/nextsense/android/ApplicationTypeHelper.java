package io.nextsense.android;

public class ApplicationTypeHelper {
  private static final String FLAVOR_CONSUMER = "consumer";
  private static final String FLAVOR_LUCID = "lucid";
  private static final String FLAVOR_RESEARCH = "research";
  private static final String FLAVOR_STUDY = "study";

  public static ApplicationType getApplicationType(String flavor) {
    if (flavor.contains(FLAVOR_CONSUMER)) {
      return ApplicationType.CONSUMER;
    } else if (flavor.contains(FLAVOR_LUCID)) {
      return ApplicationType.LUCID_REALITY;
    } else if (flavor.contains(FLAVOR_RESEARCH)) {
      return ApplicationType.RESEARCH;
    } else {
      return ApplicationType.MEDICAL;
    }
  }
}