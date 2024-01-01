import 'package:lucid_reality/domain/lucid_reality_category.dart';
import 'package:lucid_reality/ui/screens/reality_check/reality_check_base_vm.dart';
import 'package:lucid_reality/ui/screens/reality_check/set_goal_screen.dart';

class LucidRealityCategoryViewModel extends RealityCheckBaseViewModel {
  final List<LucidRealityCategory> _lucidRealityCategories = List.empty(growable: true);

  List<LucidRealityCategory> get lucidRealityCategories => _lucidRealityCategories;

  @override
  void init() async {
    _prepareLucidRealityCategories();
    super.init();
  }

  void _prepareLucidRealityCategories() {
    _lucidRealityCategories.add(LucidRealityCategory(LucidRealityCategoryEnum.c1));
    _lucidRealityCategories.add(LucidRealityCategory(LucidRealityCategoryEnum.c2));
    _lucidRealityCategories.add(LucidRealityCategory(LucidRealityCategoryEnum.c3));
    _lucidRealityCategories.add(LucidRealityCategory(LucidRealityCategoryEnum.c4));
    _lucidRealityCategories.add(LucidRealityCategory(LucidRealityCategoryEnum.c5));
    _lucidRealityCategories.add(LucidRealityCategory(LucidRealityCategoryEnum.c6));
  }

  void navigateToSetGoalScreen() {
    navigation.navigateTo(SetGoalScreen.id, replace: true);
  }
}
