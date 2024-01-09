import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:lucid_reality/di.dart';
import 'package:lucid_reality/domain/article.dart';
import 'package:lucid_reality/ui/screens/learn/article_details.dart';
import 'package:lucid_reality/ui/screens/navigation.dart';
import 'package:lucid_reality/ui/screens/reality_check/lucid_reality_category_screen.dart';

class DashboardScreenViewModel extends ViewModel {
  final Navigation _navigation = getIt<Navigation>();
  Function(int tabIndex)? changeTab;

  void onInsightItemClick(InsightLearnItem insightLearnItem) {
    changeTab?.call(1);
    _navigation.navigateTo(ArticleDetailsScreen.id, arguments: insightLearnItem.article);
  }

  void navigateToPVTTab() {
    changeTab?.call(2);
  }

  void navigateToCategoryScreen() {
    changeTab?.call(3);
    _navigation.navigateTo(LucidRealityCategoryScreen.id);
  }
}
