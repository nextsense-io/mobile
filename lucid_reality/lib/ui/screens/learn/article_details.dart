import 'package:flutter/material.dart';
import 'package:flutter_common/ui/components/scrollable_column.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:lucid_reality/domain/article.dart';
import 'package:lucid_reality/ui/components/app_body.dart';
import 'package:lucid_reality/ui/components/app_card.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
import 'package:lucid_reality/ui/screens/learn/learn_screen_vm.dart';
import 'package:lucid_reality/utils/text_theme.dart';
import 'package:lucid_reality/utils/utils.dart';
import 'package:stacked/stacked.dart';

class ArticleDetailsScreen extends HookWidget {
  static const String id = 'article_details';
  final Article article;

  const ArticleDetailsScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder.reactive(
      viewModelBuilder: () => LearnScreenViewModel(),
      builder: (context, viewModel, child) {
        return SafeArea(
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: NextSenseColors.transparent,
              elevation: 0,
              leading: InkWell(
                onTap: () {
                  viewModel.goBack();
                },
                child: Image(
                  image: Svg(imageBasePath.plus('backward_arrow.svg')),
                ),
              ),
            ),
            body: AppBody(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ScrollableColumn(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: ArticleHeroTag,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          imageBasePath.plus(article.image),
                          width: double.maxFinite,
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                    ),
                    SizedBox(height: 14),
                    Flexible(
                      child: AppCard(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              overflow: TextOverflow.ellipsis,
                              article.headline,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLargeWithFontWeight600
                                  ?.copyWith(color: NextSenseColors.royalBlue),
                            ),
                            SizedBox(height: 8),
                            Text(
                              article.content,
                              style: Theme.of(context).textTheme.bodySmall,
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
