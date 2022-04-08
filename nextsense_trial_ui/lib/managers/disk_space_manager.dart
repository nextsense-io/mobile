import 'package:disk_space/disk_space.dart';

class DiskSpaceManager {

  // Needs a minimum of disk space to store incoming data in the local database
  // before uploading to the cloud. 10MB should last only around 1 minute as
  // the database has a lot of overhead.
  static final double mbPerMinute = 10;

  double? _freeDiskSpace;

  Future<bool> isDiskSpaceSufficient(Duration protocolMinTime) async {
    await refreshAvailableDiskSpace();
    return _freeDiskSpace == null ? false :
        _freeDiskSpace! >= protocolMinTime.inMinutes * mbPerMinute;
  }

  Future refreshAvailableDiskSpace() async {
    _freeDiskSpace = await DiskSpace.getFreeDiskSpace;
  }

  double? getFreeDiskSpaceMb() {
    return _freeDiskSpace;
  }
}