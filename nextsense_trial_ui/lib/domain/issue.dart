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
  // Link to the flutter application log in firebase.
  log_link_flutter,
  // Link to the native application log in firebase.
  log_link_native,
}

class Issue extends FirebaseEntity<IssueKey> {

  Issue(FirebaseEntity firebaseEntity) : super(firebaseEntity.getDocumentSnapshot());
}