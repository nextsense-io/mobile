import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucid_reality/domain/lucid_reality_category.dart';
import 'package:lucid_reality/ui/components/app_body.dart';
import 'package:lucid_reality/ui/components/app_close_button.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
import 'package:lucid_reality/ui/screens/reality_check/lucid_reality_category_vm.dart';
import 'package:lucid_reality/utils/text_theme.dart';
import 'package:lucid_reality/utils/utils.dart';
import 'package:stacked/stacked.dart';

class LucidRealityCategoryScreen extends HookWidget {
  static const String id = 'lucid_reality_category_screen';

  const LucidRealityCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder.reactive(
      viewModelBuilder: () => LucidRealityCategoryViewModel(),
      onViewModelReady: (viewModel) => viewModel.init(),
      builder: (context, viewModel, child) {
        return SafeArea(
          child: Scaffold(
            body: AppBody(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: AppCloseButton(
                        onPressed: () {
                          viewModel.goBack();
                        },
                      ),
                    ),
                    Text(
                      'Lucid Reality',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'What would you like to achieve primarily with Lucid Dreaming? ',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemBuilder: (context, index) {
                          final lucidRealityCategory = viewModel.lucidRealityCategories[index];
                          return InkWell(
                            onTap: () async {
                              await viewModel.lucidManager
                                  .updateCategoryId(lucidRealityCategory.category.name);
                              viewModel.navigateToSetGoalScreen();
                            },
                            child: _lucidRealityCategoryItem(context, lucidRealityCategory),
                          );
                        },
                        itemCount: viewModel.lucidRealityCategories.length,
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

  Widget _lucidRealityCategoryItem(context, LucidRealityCategory lucidRealityCategory) {
    return Container(
      height: 200,
      width: 174,
      decoration: ShapeDecoration(
        color: NextSenseColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: Image.asset(
                imageBasePath.plus(lucidRealityCategory.image),
                fit: BoxFit.fitWidth,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: Text(
                lucidRealityCategory.category.title,
                style: Theme.of(context).textTheme.bodyMediumWithFontWeight700,
              ),
            ),
          )
        ],
      ),
    );
  }
}
