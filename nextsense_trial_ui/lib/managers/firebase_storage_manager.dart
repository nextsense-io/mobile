import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/managers/firebase_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

class FirebaseStorageManager {
  final FirebaseApp _firebaseApp = getIt<FirebaseManager>().getFirebaseApp();
  final CustomLogPrinter _logger = CustomLogPrinter('FirebaseStorageManager');
  late FirebaseStorage _storage;

  FirebaseStorageManager() {
    _storage = FirebaseStorage.instanceFor(app: _firebaseApp);
  }

  Future<bool> downloadFile(String gsUrl, File destinationFile) async {
    final Reference gsReference = _storage.refFromURL(gsUrl);
    _logger.log(Level.INFO, 'Starting to download ${gsUrl}');
    try {
      await gsReference.writeToFile(destinationFile);
    } on FirebaseException catch (e) {
      _logger.log(Level.SEVERE, 'Error downloading ${gsUrl}: $e');
      return false;
    }
    _logger.log(Level.INFO, 'Downloaded ${gsUrl} with success');
    return true;
  }
}