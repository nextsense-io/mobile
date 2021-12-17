import 'dart:io';

import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

/*
Return customized logger to print desire format message in console while the app
is running.
*/
CustomLogPrinter getLogger(String className) {
  return CustomLogPrinter(className);
}

/*
Save app logs to one application file so the user can upload these logs to
backend storage in case of error. Once the user upload logs to the backend, the
user can clear logs as well.
*/
class LogFile {
  static final LogFile _logFile = new LogFile._internal();

  factory LogFile() {
    return _logFile;
  }

  LogFile._internal();

  String appLogs = "*************************************************\n";

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/log.txt');
  }

  Future<void> writeData(String appLog, FileMode mode) async {
    final file = await _localFile;
    file.writeAsStringSync('$appLog' + "\n", mode: mode);
  }

  appendToAppLogs(String appLog) {
    this.appLogs += appLog + "\n";
    writeData(appLog, FileMode.append);
  }

  Future<String> readFileLogs() async {
    final file = await _localFile;
    return file.readAsStringSync();
  }

  String getAppLogs() {
    return this.appLogs;
  }

  clearApplogs() {
    this.appLogs = "*************************************************\n";
    writeData(this.appLogs, FileMode.write);
  }
}

/*
Implementation of customized logger class to change the desired format of log in
console while the app is running.
*/
class CustomLogPrinter {
  static String datalog = "";

  final String className;
  final Logger _logger;
  final DateFormat _dateFormatter = new DateFormat('yyyy:MM:dd:HH:mm:ss');

  CustomLogPrinter(this.className) : _logger = Logger(className) {
    Logger.root.level = Level.ALL;  // defaults to Level.INFO
    Logger.root.onRecord.listen((record) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    });
  }

  void log(Level logLevel, dynamic message,
      [dynamic? error, StackTrace? stackTrace]) {
    String log = '${_dateFormatter.format(new DateTime.now())} - $logLevel -'
        ' $className - $message';
    _logger.log(logLevel, message, error, stackTrace);
    LogFile().appendToAppLogs('$log');
  }
}
