import 'dart:io';

import 'package:logging/logging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_common/di.dart';
import 'package:flutter_common/managers/firebase_manager.dart';
import 'package:flutter_common/utils/android_logger.dart';

class FirebaseStorageManager {
  static const String _dataNodeName = '/data';
  static const String _baseNodeName = '/mobile';
  final FirebaseApp _firebaseApp = getIt<FirebaseManager>().getFirebaseApp();
  final CustomLogPrinter _logger = CustomLogPrinter('FirebaseStorageManager');
  late FirebaseStorage storage;
  late Reference _dataNode;
  late Reference _baseNode;

  FirebaseStorageManager() {
    storage = FirebaseStorage.instanceFor(app: _firebaseApp);
    _dataNode = storage.ref(_dataNodeName);
    _baseNode = storage.ref(_baseNodeName);
  }

  Future<bool> downloadFile(String gsUrl, File destinationFile) async {
    final Reference gsReference = storage.refFromURL(gsUrl);
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

  Future<String?> uploadStringToDataFile(String nodePath, String content) async {
    Reference storageRef = _dataNode.child(nodePath);
    return await _uploadStringToRef(storageRef, content);
  }

  Future<String?> uploadStringToFile(String nodePath, String content) async {
    Reference storageRef = _baseNode.child(nodePath);
    return await _uploadStringToRef(storageRef, content);
  }

  Future<String?> _uploadStringToRef(Reference storageRef, String content) async {
    try {
      await storageRef.putString(content, format: PutStringFormat.raw);
      return storageRef.fullPath;
    } on FirebaseException catch (e) {
      _logger.log(Level.WARNING, 'Failed to upload file to ${storageRef.fullPath}.'
          ' Exception: ${e.message}');
      return null;
    }
  }
}