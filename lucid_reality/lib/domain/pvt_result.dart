import 'package:lucid_reality/managers/firebase_realtime_db_entity.dart';

enum PVTResultKey {
  id,
  timeInterval,
  reactions,
  avg,
}

class PVTResult extends FirebaseRealtimeDBEntity<PVTResultKey> {
  static const String table = 'brainChecks';

  PVTResult();

  String? getId() {
    return getValue(PVTResultKey.id);
  }

  void setId(String id) {
    setValue(PVTResultKey.id, id);
  }

  int? getTimeInterval() {
    return getValue(PVTResultKey.timeInterval);
  }

  void setTimeInterval(int timeInterval) {
    setValue(PVTResultKey.timeInterval, timeInterval);
  }

  int getAverageTapLatencyMs() {
    return getValue(PVTResultKey.avg);
  }

  void setAverageTapLatencyMs(int averageTapLatencyMs) {
    setValue(PVTResultKey.avg, averageTapLatencyMs);
  }

  List<int> getReactions() {
    List<int> ints = [];
    final reactions = getValue(PVTResultKey.reactions);
    if (reactions != null) {
      List<Object?> objects = reactions;
      for (var obj in objects) {
        if (obj is int) {
          ints.add(obj);
        }
      }
    }
    return ints;
  }

  void setReactions(List<int> reactions) {
    setValue(PVTResultKey.reactions, reactions);
  }

  factory PVTResult.fromJson(MapEntry<String, dynamic> e) {
    PVTResult pvtResult = PVTResult();
    pvtResult.entityId = e.key;
    pvtResult.setValues(Map.from(e.value));
    return pvtResult;
  }
}
