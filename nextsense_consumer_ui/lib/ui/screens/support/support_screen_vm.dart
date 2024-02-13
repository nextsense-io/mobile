import 'package:flutter_common/managers/device_manager.dart';
import 'package:flutter_common/managers/firebase_storage_manager.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:flutter_common/domain/firebase_entity.dart';
import 'package:flutter_common/utils/android_logger.dart';
import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:nextsense_consumer_ui/di.dart';
import 'package:nextsense_consumer_ui/domain/issue.dart';
import 'package:nextsense_consumer_ui/managers/auth_manager.dart';
import 'package:nextsense_consumer_ui/managers/consumer_ui_firestore_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SupportScreenViewModel extends ViewModel {
  final CustomLogPrinter _logger = CustomLogPrinter('SupportScreenViewModel');
  final ConsumerUiFirestoreManager _firestoreManager = getIt<ConsumerUiFirestoreManager>();
  final FirebaseStorageManager _firebaseStorageManager = getIt<FirebaseStorageManager>();
  final AuthManager _authManager = getIt<AuthManager>();
  final DeviceManager _deviceManager = getIt<DeviceManager>();

  String? issueDescription;
  bool attachLog = false;
  String? version = '';
  Device? connectedDevice;


  @override
  void init() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    version = packageInfo.version;
    if (_deviceManager.deviceIsReady) {
      connectedDevice = _deviceManager.getConnectedDevice();
    }
    setInitialised(true);
    notifyListeners();
  }

  Future<bool> submitIssue() async {
    setBusy(true);
    notifyListeners();
    _logger.log(Level.INFO, 'Issue submitted by the user.');
    FirebaseEntity issueEntity = await _firestoreManager.addAutoIdEntity(
        [Table.users, Table.issues], [_authManager.user!.id]);
    Issue issue = Issue(issueEntity);
    issue
      ..setValue(IssueKey.description, issueDescription)
      ..setValue(IssueKey.status, IssueState.creating);
    String? logLinkFlutter;
    String? logLinkNative;
    if (attachLog) {
      logLinkFlutter = await _firebaseStorageManager.uploadStringToFile(
          '/users/${_authManager.username}/issues/${issueEntity.id}_flutter.txt',
          await _logger.getLogFileContent());
      logLinkNative = await _firebaseStorageManager.uploadStringToFile(
          '/users/${_authManager.username}/issues/${issueEntity.id}_native.txt',
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