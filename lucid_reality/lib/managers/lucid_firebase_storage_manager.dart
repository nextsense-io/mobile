import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_common/managers/firebase_storage_manager.dart';
import 'package:flutter_common/utils/android_logger.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

class LucidFirebaseStorageManager extends FirebaseStorageManager {
  final CustomLogPrinter _logger = CustomLogPrinter('LucidFirebaseStorageManager');
  static const String _recordingNodeName = '/recordings';
  static const String _drawingNodeName = '/drawings';
  late FirebaseStorage _storage;
  late Reference _recordingNode;
  late Reference _drawingNode;

  LucidFirebaseStorageManager() : super() {
    _recordingNode = _storage.ref(_recordingNodeName);
    _drawingNode = _storage.ref(_drawingNodeName);
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
