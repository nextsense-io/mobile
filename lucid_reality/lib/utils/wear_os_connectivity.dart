import 'dart:convert';

import 'package:flutter_common/utils/android_logger.dart';
import 'package:flutter_wear_os_connectivity/flutter_wear_os_connectivity.dart';
import 'package:logging/logging.dart';
import 'package:lucid_reality/domain/reality_test.dart';

const LUCID_NOTIFICATION_SETTINGS_PATH = "/LucidNotificationSettings";
const LUCID_NOTIFICATION_SETTINGS_KEY = "/LucidSettings";
const LUCID_LOGIN_STATUS_PATH = "/LucidLoginStatus";
const LUCID_LOGIN_STATUS_KEY = "/isUserLogin";

class LucidWearOsConnectivity {
  final _logger = CustomLogPrinter('LucidWearOsConnectivity');
  FlutterWearOsConnectivity _flutterWearOsConnectivity = FlutterWearOsConnectivity();

  LucidWearOsConnectivity() {
    _flutterWearOsConnectivity.configureWearableAPI();
  }

  Future<void> sendDataToWearOS(String dataPath, String dataKey, String dataValue) async {
    DataItem? _dataItem = await _flutterWearOsConnectivity.syncData(
        path: dataPath, data: {dataKey: dataValue}, isUrgent: true);
    _logger.log(Level.INFO, 'Data sent to Wear OS ${_dataItem.toString()}');
  }

  Future<void> syncToWearOSUserLoginStatus({required bool isUserLogin}) async {
    DataItem? _dataItem = await _flutterWearOsConnectivity.syncData(
        path: LUCID_LOGIN_STATUS_PATH, data: {LUCID_LOGIN_STATUS_KEY: isUserLogin}, isUrgent: true);
    _logger.log(Level.INFO, 'Data sent to Wear OS ${_dataItem.toString()}');
  }

  Future<void> syncToWearOSRealitySettings({required RealityTest realityTest}) async {
    DataItem? _dataItem = await _flutterWearOsConnectivity.syncData(
        path: LUCID_NOTIFICATION_SETTINGS_PATH,
        data: {LUCID_NOTIFICATION_SETTINGS_KEY: jsonEncode(realityTest.getValues())},
        isUrgent: true);
    _logger.log(Level.INFO, 'Data sent to Wear OS ${_dataItem.toString()}');
  }

  Future<bool> isCompanionAppInstalled() async {
    final List<WearOsDevice> connectedDevices =
        await _flutterWearOsConnectivity.getConnectedDevices();
    return connectedDevices.isNotEmpty;
  }
}
