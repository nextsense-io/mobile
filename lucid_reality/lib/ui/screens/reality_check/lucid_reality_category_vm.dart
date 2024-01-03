import 'package:lucid_reality/domain/lucid_reality_category.dart';
import 'package:lucid_reality/ui/screens/reality_check/reality_check_base_vm.dart';
import 'package:lucid_reality/ui/screens/reality_check/set_goal_screen.dart';

class LucidRealityCategoryViewModel extends RealityCheckBaseViewModel {
  final List<LucidRealityCategory> _lucidRealityCategories = List.of(
      LucidRealityCategoryEnum.values.map((category) => LucidRealityCategory(category)).toList());

  List<LucidRealityCategory> get lucidRealityCategories => _lucidRealityCategories;

  @override
  void init() async {
    super.init();
  }

  void navigateToSetGoalScreen() {
    navigation.navigateTo(SetGoalScreen.id, replace: true);
  }
}
