import 'package:flutter_common/di.dart';
import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:lucid_reality/domain/article.dart';
import 'package:lucid_reality/managers/article_manager.dart';
import 'package:lucid_reality/ui/screens/learn/article_details.dart';
import 'package:lucid_reality/ui/screens/navigation.dart';

const ArticleHeroTag = 'articleDetails';

class LearnScreenViewModel extends ViewModel {
  final Navigation _navigation = getIt<Navigation>();
  final ArticleManager _articleManager = ArticleManager();

  List<Article> get articles => _articleManager.articles;

  @override
  void init() async {
    super.init();
    setBusy(true);
    await _articleManager.prepareArticles();
    setBusy(false);
  }

  void goBack() {
    _navigation.pop();
  }

  void navigateToArticleDetailsScreen(Article article) {
    _navigation.navigateTo(ArticleDetailsScreen.id, arguments: article);
  }
}
