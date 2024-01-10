import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class StorageManager {
  static const String _recordingsDir = 'recordings';
  static const String _drawingsDir = 'drawings';

  Directory? _appDocumentsRoot;

  StorageManager() {
    _initAppRootDir();
  }

  Future _initAppRootDir() async {
    if (_appDocumentsRoot == null) {
      _appDocumentsRoot = await getApplicationDocumentsDirectory();
    }
  }

  Directory _getRecordingDir() {
    return Directory("${_appDocumentsRoot!.absolute.path}/$_recordingsDir");
  }

  Directory _getDrawingDir() {
    return Directory("${_appDocumentsRoot!.absolute.path}/$_drawingsDir");
  }

  File getNewRecordingFile() {
    _getRecordingDir().createSync(recursive: true);
    return File(
        '${_getRecordingDir().absolute.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a');
  }

  File _getNewDrawingFile() {
    _getDrawingDir().createSync(recursive: true);
    return File(
        '${_getDrawingDir().absolute.path}/drawing_${DateTime.now().millisecondsSinceEpoch}.png');
  }

  Future<File> writeToFile(ByteData data) async {
    final buffer = data.buffer;
    return _getNewDrawingFile()
        .writeAsBytes(buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

  Future<bool> isRecordingFileExist(String gsUrl) async {
    _getRecordingDir().createSync(recursive: true);
    return File('${_getRecordingDir().absolute.path}/${path.basename(gsUrl)}').existsSync();
  }
}
