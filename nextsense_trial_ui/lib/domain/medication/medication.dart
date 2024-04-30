enum MedicationState {
  before_time,  // Not yet time to take this medication.
  skipped,  // Did not take this medication.
  taken_on_time,  // Took this medication at the right time.
  taken_late,  // Took this medication after the right time.
  taken_early,  // Took this medication before the right time.
  unknown;

  factory MedicationState.fromString(String key) {
    return MedicationState.values.firstWhere((e) => e.toString() == 'MedicationState.$key',
        orElse: () => MedicationState.unknown);
  }
}