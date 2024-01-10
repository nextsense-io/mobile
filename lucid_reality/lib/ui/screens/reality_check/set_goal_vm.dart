import 'package:lucid_reality/ui/screens/reality_check/reality_check_base_vm.dart';
import 'package:lucid_reality/ui/screens/reality_check/reality_check_time_screen.dart';

class SetGoalViewModel extends RealityCheckBaseViewModel {
  void navigateToSetTimerScreen() {
    navigation.navigateTo(RealityCheckTimeScreen.id, replace: true);
  }
}
