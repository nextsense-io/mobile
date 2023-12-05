import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:lucid_reality/ui/screens/dashboard/dashboard_screen.dart';

import 'package:lucid_reality/di.dart';
import 'package:lucid_reality/ui/screens/navigation.dart';

class OnboardingScreenViewModel extends ViewModel {
  final Navigation _navigation = getIt<Navigation>();

  void redirectToDashboard() {
    _navigation.navigateTo(DashboardScreen.id, replace: true);
  }
}
