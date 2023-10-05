import 'dart:io';

import 'package:logging/logging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_common/di.dart';
import 'package:flutter_common/managers/firebase_manager.dart';
import 'package:flutter_common/utils/android_logger.dart';

class FirebaseStorageManager {
  static const String _baseNodeName = '/mobile';
  final FirebaseApp _firebaseApp = getIt<FirebaseManager>().getFirebaseApp();
  final CustomLogPrinter _logger = CustomLogPrinter('FirebaseStorageManager');
  late FirebaseStorage _storage;
  late Reference _baseNode;

  FirebaseStorageManager() {
    _storage = FirebaseStorage.instanceFor(app: _firebaseApp);
    _baseNode = _storage.ref(_baseNodeName);
  }

  Future<bool> downloadFile(String gsUrl, File destinationFile) async {
    final Reference gsReference = _storage.refFromURL(gsUrl);
    _logger.log(Level.INFO, 'Starting to download $gsUrl');
    try {
      await gsReference.writeToFile(destinationFile);
    } on FirebaseException catch (e) {
      _logger.log(Level.SEVERE, 'Error downloading $gsUrl: $e');
      return false;
    }
    _logger.log(Level.INFO, 'Downloaded $gsUrl with success');
    return true;
  }

  Future<String?> uploadStringToFile(String nodePath, String content) async {
    Reference storageRef = _baseNode.child(nodePath);
    try {
      await storageRef.putString(content, format: PutStringFormat.raw);
      return storageRef.fullPath;
    } on FirebaseException catch (e) {
      _logger.log(Level.WARNING, 'Failed to upload string content to ${storageRef.fullPath}.'
          ' Exception: ${e.message}');
      return null;
    }
  }
}