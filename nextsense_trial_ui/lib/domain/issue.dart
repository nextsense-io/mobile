import 'package:nextsense_trial_ui/domain/firebase_entity.dart';

enum IssueState {
  open,
  assigned,
  resolved
}

/**
 * Each entry corresponds to a field name in the database instance.
 */
enum IssueKey {
  // Description of the issue from the user.
  description,
  // State of the issue, see `IssueState`.
  status,
  // Link to the application log in firebase.
  log_link,
  // When the issue was reported.
  created_at,
  // When the issue was last updated.
  updated_at
}

class Issue extends FirebaseEntity<IssueKey> {

  Issue(FirebaseEntity firebaseEntity) : super(firebaseEntity.getDocumentSnapshot());
}