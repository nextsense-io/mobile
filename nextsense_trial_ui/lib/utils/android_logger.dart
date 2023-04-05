import 'dart:io';

import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

/*
Return customized logger to print desire format message in console while the app is running.
*/
CustomLogPrinter getLogger(String className) {
  return CustomLogPrinter(className);
}

/*
Save app logs to one application file so the user can upload these logs to backend storage in case
of error. Once the user upload logs to the backend, the user can clear logs as well.
*/
class LogFile {
  static final LogFile _logFile = new LogFile._internal();
  static final String _startLine = '*************************************************\n';
  static const int _maxLogAgeInDays = 2;

  factory LogFile() {
    return _logFile;
  }

  LogFile._internal() {
    _cleanupLogFiles();
  }

  String appLogs = _startLine;

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/app_log_${getFileDateSuffix(DateTime.now())}.txt');
  }

  String getFileDateSuffix(DateTime date) {
    return '${date.year}_${date.month}_${date.day}';
  }

  Future<void> _writeData(String appLog, FileMode mode) async {
    final file = await _localFile;
    file.writeAsStringSync('$appLog' + '\n', mode: mode);
  }

  appendToAppLogs(String appLog) {
    this.appLogs += appLog + '\n';
    _writeData(appLog, FileMode.append);
  }

  Future<String> getAppLogs() async {
    final logFiles = Directory(await _localPath).listSync()
        .where((logFile) => logFile is File && logFile.path.endsWith('.txt'))
        .toList(growable: false)
      ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified))..reversed;
    final recentLogFiles = logFiles.take(2).toList(growable: false);
    final logTextBuilder = StringBuffer();
    for (final logFile in recentLogFiles) {
      final file = logFile as File;
      final logText = file.readAsStringSync();
      logTextBuilder.write(logText);
    }
    return logTextBuilder.toString();
  }

  Future _cleanupLogFiles() async {
    final now = DateTime.now();
    final cutoffTime = now.subtract(Duration(days: _maxLogAgeInDays));
    Directory(await _localPath).listSync().forEach((logFile) {
      if (logFile is File && logFile.path.endsWith('.txt')) {
        final modifiedTime = logFile.lastModifiedSync();
        if (modifiedTime.isBefore(cutoffTime)) {
          logFile.deleteSync();
        }
      }
    });
  }

  // String getAppLogs() {
  //   return this.appLogs;
  // }
}

/*
Implementation of customized logger class to change the desired format of log in console while the
app is running.
*/
class CustomLogPrinter {
  static final DateFormat _dateFormatter = new DateFormat('yyyy:MM:dd:HH:mm:ss');

  final String className;
  final Logger _logger;

  CustomLogPrinter(this.className) : _logger = Logger(className) {}

  void log(Level logLevel, dynamic message, [dynamic error, StackTrace? stackTrace]) {
    String log = '${_dateFormatter.format(new DateTime.now())} - $logLevel - $className - $message';
    _logger.log(logLevel, '$className - $message', error, stackTrace);
    LogFile().appendToAppLogs('$log');
  }

  Future<String> getLogFileContent() async {
    return await LogFile().getAppLogs();
  }
}
