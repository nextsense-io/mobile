import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:lucid_reality/di.dart';
import 'package:lucid_reality/ui/screens/navigation.dart';

class REMDetectionOnboardingViewModel extends ViewModel {
  final Navigation navigation = getIt<Navigation>();

  @override
  void init() {
    super.init();
  }

  void navigateToLucidScreen() {
    navigation.pop();
    print("navigateToLucidScreen");
  }
}
