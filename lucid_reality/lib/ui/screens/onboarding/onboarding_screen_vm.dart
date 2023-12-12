import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:lucid_reality/di.dart';
import 'package:lucid_reality/domain/question.dart';
import 'package:lucid_reality/domain/users_entity.dart';
import 'package:lucid_reality/managers/auth_manager.dart';
import 'package:lucid_reality/managers/firebase_realtime_db_entity.dart';
import 'package:lucid_reality/managers/lucid_ui_firebase_realtime_db_manager.dart';
import 'package:lucid_reality/ui/screens/dashboard/dashboard_screen.dart';
import 'package:lucid_reality/ui/screens/navigation.dart';

class OnboardingScreenViewModel extends ViewModel {
  final Navigation _navigation = getIt<Navigation>();
  final AuthManager _authManager = getIt<AuthManager>();
  final firebaseRealTimeDb = getIt<LucidUiFirebaseRealtimeDBManager>();

  void redirectToDashboard() {
    _navigation.navigateTo(DashboardScreen.id, replace: true);
  }

  void updateGoal(Goal goal) async {
    _authManager.user?.setGoal(goal.tag);
    if (_authManager.user != null && _authManager.authUid != null) {
      await firebaseRealTimeDb.setEntity(
          _authManager.user!, UserEntity.table.where(_authManager.authUid!));
    }
  }
}
