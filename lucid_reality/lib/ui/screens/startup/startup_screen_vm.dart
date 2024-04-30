import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:lucid_reality/di.dart';
import 'package:lucid_reality/managers/auth_manager.dart';
import 'package:lucid_reality/ui/screens/dashboard/dashboard_screen.dart';
import 'package:lucid_reality/ui/screens/navigation.dart';

class StartupScreenViewModel extends ViewModel {
  final Navigation _navigation = getIt<Navigation>();
  final _authManager = getIt<AuthManager>();

  @override
  void init() async {
    await _authManager.ensureUserLoaded();
    redirectToDashboard();
  }

  void redirectToDashboard() {
    _navigation.navigateTo(DashboardScreen.id, replace: true);
  }
}
