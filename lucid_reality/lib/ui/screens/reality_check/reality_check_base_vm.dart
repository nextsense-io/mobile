import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:lucid_reality/di.dart';
import 'package:lucid_reality/managers/auth_manager.dart';
import 'package:lucid_reality/managers/lucid_manager.dart';
import 'package:lucid_reality/managers/lucid_ui_firebase_realtime_db_manager.dart';
import 'package:lucid_reality/ui/screens/navigation.dart';

class RealityCheckBaseViewModel extends ViewModel {
  final Navigation navigation = getIt<Navigation>();
  final AuthManager _authManager = getIt<AuthManager>();
  final LucidManager lucidManager = getIt<LucidManager>();

  @override
  void init() async {
    super.init();
    final userLoaded = await _authManager.ensureUserLoaded();
    if (userLoaded) {
      await lucidManager.fetchIntent();
      notifyListeners();
    }
  }

  void goBack() {
    navigation.pop();
  }
}
