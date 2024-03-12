/* Acceleration data class. */
class AccelerationData implements Comparable<AccelerationData> {
  final int x;
  final int y;
  final int z;
  final DateTime timestamp;

  AccelerationData({required this.x, required this.y, required this.z, required this.timestamp});

  int getX() {
    return x;
  }

  int getY() {
    return y;
  }

  int getZ() {
    return z;
  }

  int getTimestampMs() {
    return timestamp.millisecondsSinceEpoch;
  }

  List<int> asList() {
    return [x, y, z];
  }

  List<int> asListWithTimestamp() {
    return [x, y, z, timestamp.millisecondsSinceEpoch];
  }

  @override
  int compareTo(AccelerationData other) {
    return timestamp
        .difference(other.timestamp)
        .inMilliseconds;
  }
}
