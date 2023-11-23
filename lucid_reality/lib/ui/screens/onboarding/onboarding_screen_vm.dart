import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:lucid_reality/ui/screens/dashboard/dashboard_screen.dart';

import '../../../di.dart';
import '../navigation.dart';

class OnboardingScreenViewModel extends ViewModel {
  final Navigation _navigation = getIt<Navigation>();

  void redirectToDashboard() {
    _navigation.navigateTo(DashboardScreen.id, replace: true);
  }
}
