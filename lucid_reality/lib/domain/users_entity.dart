import 'package:lucid_reality/managers/firebase_realtime_db_entity.dart';

enum UserKey { email, name, goal }

class UsersEntity extends FirebaseRealtimeDBEntity<UserKey> {
  static const String table = 'users';

  String? getEmail() {
    return getValue(UserKey.email);
  }

  void setEmail(String email) {
    setValue(UserKey.email, email);
  }

  void setUserName(String userName) {
    setValue(UserKey.name, userName);
  }

  String? getUsername() {
    return getValue(UserKey.name);
  }

  void setGoal(String goal) {
    setValue(UserKey.goal, goal);
  }

  String? getGoal() {
    return getValue(UserKey.goal);
  }
}
