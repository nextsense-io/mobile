import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:lucid_reality/di.dart';
import 'package:lucid_reality/domain/article.dart';
import 'package:lucid_reality/managers/auth_manager.dart';
import 'package:lucid_reality/preferences.dart';
import 'package:lucid_reality/ui/screens/dashboard/dashboard_screen.dart';
import 'package:lucid_reality/ui/screens/learn/article_details.dart';
import 'package:lucid_reality/ui/screens/navigation.dart';
import 'package:lucid_reality/ui/screens/pvt_onboarding/pvt_onboarding_screen.dart';
import 'package:lucid_reality/ui/screens/reality_check/lucid_reality_category_screen.dart';

class DashboardScreenViewModel extends ViewModel {
  final Navigation _navigation = getIt<Navigation>();
  final AuthManager _authManager = getIt<AuthManager>();
  final _preferences = getIt<Preferences>();
  Function(DashboardTab tab)? changeTab;

  void onInsightItemClick(InsightLearnItem insightLearnItem) {
    changeTab?.call(DashboardTab.learn);
    _navigation.navigateTo(ArticleDetailsScreen.id, arguments: insightLearnItem.article);
  }

  void navigateToPVTTab() {
    changeTab?.call(DashboardTab.pvt);
    if (!isPVTOnboardingCompleted) {
      navigateToPVTOnboardingScreen();
    }
  }

  void navigateToCategoryScreen() {
    changeTab?.call(DashboardTab.lucid);
    _navigation.navigateTo(LucidRealityCategoryScreen.id);
  }

  void navigateToPVTOnboardingScreen() {
    _navigation.navigateTo(PVTOnboardingScreen.id);
    _preferences.setBool(PreferenceKey.isPVTOnboardingCompleted, true);
  }

  String getUserName() => _authManager.userName;

  bool get isPVTOnboardingCompleted => _preferences.getBool(PreferenceKey.isPVTOnboardingCompleted);
}
