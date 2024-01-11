import 'package:flutter/material.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:lucid_reality/domain/article.dart';
import 'package:lucid_reality/managers/article_manager.dart';
import 'package:lucid_reality/ui/components/app_card.dart';
import 'package:lucid_reality/utils/text_theme.dart';
import 'package:lucid_reality/utils/utils.dart';

class InsightLearn extends StatelessWidget {
  final ArticleManager _articleManager = ArticleManager();
  final Function(InsightLearnItem insightLearnItem) onItemClick;

  InsightLearn({super.key, required this.onItemClick});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        _articleManager.getInsightLearnItems().length * 2 - 1,
        (index) {
          if (index.isOdd) {
            return VerticalDivider(
              width: 2,
              color: Colors.transparent, // Adjust color as needed
            );
          } else {
            final itemIndex = index ~/ 2;
            return buildLearnItem(
              context,
              _articleManager.getInsightLearnItems()[itemIndex],
            );
          }
        },
      ),
    );
  }

  Widget buildLearnItem(BuildContext context, InsightLearnItem insightLearnItem) {
    return Flexible(
      child: InkWell(
        onTap: () {
          onItemClick.call(insightLearnItem);
        },
        child: AppCard(
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image(image: Svg(imageBasePath.plus(insightLearnItem.image))),
              const SizedBox(height: 12),
              Text(
                insightLearnItem.title,
                style: Theme.of(context)
                    .textTheme
                    .bodySmallWithFontWeight700FontSize12
                    ?.copyWith(color: insightLearnItem.color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
