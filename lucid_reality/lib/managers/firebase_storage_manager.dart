import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_common/di.dart';
import 'package:flutter_common/managers/firebase_manager.dart';
import 'package:flutter_common/utils/android_logger.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

class FirebaseStorageManager {
  static const String _recordingNodeName = '/recordings';
  static const String _drawingNodeName = '/drawings';
  final FirebaseApp _firebaseApp = getIt<FirebaseManager>().getFirebaseApp();
  final CustomLogPrinter _logger = CustomLogPrinter('FirebaseStorageManager');
  late FirebaseStorage _storage;
  late Reference _recordingNode;
  late Reference _drawingNode;

  FirebaseStorageManager() {
    _storage = FirebaseStorage.instanceFor(app: _firebaseApp);
    _recordingNode = _storage.ref(_recordingNodeName);
    _drawingNode = _storage.ref(_drawingNodeName);
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

  Future<String?> uploadRecordingFile(File file) async {
    Reference storageRef = _recordingNode.child(path.basename(file.path));
    try {
      await storageRef.putFile(file);
      return storageRef.fullPath;
    } on FirebaseException catch (e) {
      _logger.log(
          Level.WARNING,
          'Failed to upload string content to ${storageRef.fullPath}.'
          ' Exception: ${e.message}');
      return null;
    }
  }

  Future<String?> uploadDrawingFile(File file) async {
    Reference storageRef = _drawingNode.child(path.basename(file.path));
    try {
      await storageRef.putFile(file);
      return storageRef.fullPath;
    } on FirebaseException catch (e) {
      _logger.log(
          Level.WARNING,
          'Failed to upload string content to ${storageRef.fullPath}.'
              ' Exception: ${e.message}');
      return null;
    }
  }
}
