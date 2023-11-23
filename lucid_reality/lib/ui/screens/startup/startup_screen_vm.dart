import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:lucid_reality/ui/screens/onboarding/onboarding_screen.dart';

import '../../../di.dart';
import '../navigation.dart';

class StartupScreenViewModel extends ViewModel {
  final Navigation _navigation = getIt<Navigation>();

  @override
  void init() async {
    Future.delayed(
      const Duration(milliseconds: 2000),
      () => {redirectToOnboarding()},
    );
  }

  void redirectToOnboarding() {
    _navigation.navigateTo(OnboardingScreen.id, replace: true);
  }
}
