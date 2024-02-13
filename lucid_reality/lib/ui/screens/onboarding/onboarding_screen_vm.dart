import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:lucid_reality/di.dart';
import 'package:lucid_reality/domain/question.dart';
import 'package:lucid_reality/domain/user_entity.dart';
import 'package:lucid_reality/managers/auth_manager.dart';
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
    final userLoaded = await _authManager.ensureUserLoaded();
    if (userLoaded) {
      _authManager.user?.setGoal(goal.tag);
      await firebaseRealTimeDb.updateEntity(_authManager.user!, UserEntity.table);
    }
  }
}
