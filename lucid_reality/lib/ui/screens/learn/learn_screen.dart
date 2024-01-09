import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucid_reality/domain/article.dart';
import 'package:lucid_reality/ui/components/app_body.dart';
import 'package:lucid_reality/ui/components/app_card.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
import 'package:lucid_reality/ui/screens/learn/learn_screen_vm.dart';
import 'package:lucid_reality/utils/text_theme.dart';
import 'package:lucid_reality/utils/utils.dart';
import 'package:stacked/stacked.dart';

class LearnScreen extends HookWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder.reactive(
      viewModelBuilder: () => LearnScreenViewModel(),
      onViewModelReady: (viewModel) => viewModel.init(),
      builder: (context, viewModel, child) {
        return SafeArea(
          child: Scaffold(
            body: AppBody(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Learn',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 23),
                    Text(
                      'RECENT',
                      style: Theme.of(context).textTheme.bodyMediumWithFontWeight600,
                    ),
                    SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        itemBuilder: (context, index) {
                          final article = viewModel.articles[index];
                          return InkWell(
                            onTap: () {
                              viewModel.navigateToArticleDetailsScreen(article);
                            },
                            child: rowArticleItem(context, article),
                          );
                        },
                        separatorBuilder: (context, index) {
                          return Divider(
                            thickness: 4,
                            color: Colors.transparent,
                          );
                        },
                        itemCount: viewModel.articles.length,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget rowArticleItem(BuildContext context, Article article) {
    return AppCard(
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: ArticleHeroTag,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                imageBasePath.plus(article.image),
                height: 124,
                width: 102,
                fit: BoxFit.fitHeight,
              ),
            ),
          ),
          SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  overflow: TextOverflow.ellipsis,
                  article.headline,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmallWithFontWeight600FontSize13
                      ?.copyWith(color: NextSenseColors.royalBlue),
                  maxLines: 2,
                ),
                SizedBox(height: 8),
                Text(
                  overflow: TextOverflow.ellipsis,
                  article.content,
                  style: Theme.of(context).textTheme.bodySmallWithFontWeight600FontSize13,
                  maxLines: 5,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
