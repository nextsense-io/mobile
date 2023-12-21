import 'package:flutter_common/di.dart';
import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:lucid_reality/managers/auth_manager.dart';
import 'package:lucid_reality/managers/lucid_manager.dart';
import 'package:lucid_reality/ui/screens/navigation.dart';
import 'package:lucid_reality/ui/screens/reality_check/lucid_reality_category_screen.dart';

class LucidScreenViewModel extends ViewModel {
  final Navigation _navigation = getIt<Navigation>();
  final AuthManager _authManager = getIt<AuthManager>();
  final LucidManager _lucidManager = getIt<LucidManager>();

  @override
  void init() async {
    super.init();
    final userLoaded = await _authManager.ensureUserLoaded();
    if (userLoaded) {
      await _lucidManager.fetchIntent();
      await _lucidManager.fetchRealityCheck();
      notifyListeners();
    }
  }

  void navigateToCategoryScreen() {
    _navigation.navigateTo(LucidRealityCategoryScreen.id);
  }
}
