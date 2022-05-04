import 'dart:math';

import 'package:logging/logging.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

class DiskSpaceManager {

  // Needs a minimum of disk space to store incoming data in the local database
  // before uploading to the cloud. 10MB should last only around 1 minute as
  // the database has a lot of overhead.
  static final double mbPerMinute = 10;
  // 10 minutes should be enough to cache the data as long as there is an active
  // connection.
  static final Duration _maximumTimeToReserveSpace = Duration(minutes: 10);

  final _logger = CustomLogPrinter('DiskSpaceManager');

  double? _freeDiskSpace;

  Future<bool> isDiskSpaceSufficient(Duration protocolMinTime) async {
    await refreshAvailableDiskSpace();
    double minSpaceMb = min(protocolMinTime.inMinutes,
        _maximumTimeToReserveSpace.inMinutes) * mbPerMinute;
    return _freeDiskSpace == null ? false : _freeDiskSpace! >= minSpaceMb;
  }

  Future refreshAvailableDiskSpace() async {
    _freeDiskSpace = await NextsenseBase.getFreeDiskSpaceMb();
    _logger.log(Level.INFO, 'Available disk space in MB: $_freeDiskSpace');
  }

  double? getFreeDiskSpaceMb() {
    return _freeDiskSpace;
  }
}