import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:lucid_reality/di.dart';
import 'package:lucid_reality/managers/auth_manager.dart';
import 'package:lucid_reality/managers/lucid_manager.dart';
import 'package:lucid_reality/ui/screens/navigation.dart';

class RealityCheckBaseViewModel extends ViewModel {
  final Navigation navigation = getIt<Navigation>();
  final AuthManager _authManager = getIt<AuthManager>();
  final LucidManager lucidManager = getIt<LucidManager>();

  @override
  void init() async {
    super.init();
    setBusy(true);
    final userLoaded = await _authManager.ensureUserLoaded();
    if (userLoaded) {
      await lucidManager.fetchIntent();
      await lucidManager.fetchRealityCheck();
    }
    setBusy(false);
  }

  void goBack() {
    navigation.pop();
  }

  void goBackWithResult<T extends Object?>([T? result]) {
    navigation.popWithResult(result);
  }
}
