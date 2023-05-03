import 'package:logging/logging.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/issue.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/firebase_storage_manager.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';
import 'package:nextsense_trial_ui/viewmodels/viewmodel.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SupportScreenViewModel extends ViewModel {

  final CustomLogPrinter _logger = CustomLogPrinter('SupportScreenViewModel');
  final FirestoreManager _firestoreManager = getIt<FirestoreManager>();
  final FirebaseStorageManager _firebaseStorageManager = getIt<FirebaseStorageManager>();
  final AuthManager _authManager = getIt<AuthManager>();

  String? issueDescription;
  bool attachLog = false;
  String? version = '';

  @override
  void init() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    version = packageInfo.version;
    setInitialised(true);
    notifyListeners();
  }

  Future<bool> submitIssue() async {
    setBusy(true);
    notifyListeners();
    _logger.log(Level.INFO, 'Issue submitted by the user.');
    FirebaseEntity issueEntity = await _firestoreManager.addAutoIdReference(
        [Table.users, Table.issues], [_authManager.userCode!]);
    Issue issue = Issue(issueEntity);
    issue
      ..setValue(IssueKey.description, issueDescription)
      ..setValue(IssueKey.status, IssueState.creating);
    String? logLinkFlutter;
    String? logLinkNative;
    if (attachLog) {
      logLinkFlutter = await _firebaseStorageManager.uploadStringToFile(
          '/users/${_authManager.userCode}/issues/${issueEntity.id}_flutter.txt',
          await _logger.getLogFileContent());
      logLinkNative = await _firebaseStorageManager.uploadStringToFile(
          '/users/${_authManager.userCode}/issues/${issueEntity.id}_native.txt',
          await NextsenseBase.getNativeLogs());
      if (logLinkFlutter == null || logLinkNative == null) {
        return false;
      }
    }
    issue
      ..setValue(IssueKey.status, IssueState.created.name)
      ..setValue(IssueKey.log_link_flutter, logLinkFlutter)
      ..setValue(IssueKey.log_link_native, logLinkNative);
    bool success = await issue.save();
    setBusy(false);
    notifyListeners();
    return success;
  }
}