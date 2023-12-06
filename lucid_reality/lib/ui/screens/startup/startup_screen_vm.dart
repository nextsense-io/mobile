import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:lucid_reality/di.dart';
import 'package:lucid_reality/ui/screens/auth/sign_in_screen.dart';
import 'package:lucid_reality/ui/screens/navigation.dart';
import 'package:lucid_reality/ui/screens/onboarding/onboarding_screen.dart';

class StartupScreenViewModel extends ViewModel {
  final Navigation _navigation = getIt<Navigation>();

  @override
  void init() async {
    Future.delayed(
      const Duration(milliseconds: 2000),
      () => {redirectToSignInScreen()},
    );
  }

  void redirectToOnboarding() {
    _navigation.navigateTo(OnboardingScreen.id, replace: true);
  }

  void redirectToSignInScreen() {
    _navigation.navigateTo(SignInScreen.id, replace: true);
  }
}
