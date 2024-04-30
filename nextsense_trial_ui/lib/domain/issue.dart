import 'package:flutter_common/domain/firebase_entity.dart';

enum IssueState {
  creating,  // Issue is being created, logs getting uploaded etc...
  created,  // Issue is created. Ready to notify support.
  open,  // Issue was notified to support and is ready to be assigned.
  assigned,  // Issue is assigned to someone from support.
  resolved  // Issue has been resolved
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

  Issue(FirebaseEntity firebaseEntity) :
        super(firebaseEntity.getDocumentSnapshot(), firebaseEntity.getFirestoreManager());
}