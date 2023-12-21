import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:lucid_reality/domain/tone_category.dart';
import 'package:lucid_reality/ui/components/app_body.dart';
import 'package:lucid_reality/ui/components/app_close_button.dart';
import 'package:lucid_reality/ui/components/reality_check_bottom_bar.dart';
import 'package:lucid_reality/utils/text_theme.dart';
import 'package:lucid_reality/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:stacked/stacked.dart';

import 'reality_check_tone_category_vm.dart';

class RealityCheckToneCategoryScreen extends HookWidget {
  static const String id = 'reality_check_tone_category_screen';

  const RealityCheckToneCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedIndex = useState(0);
    return ViewModelBuilder.reactive(
      viewModelBuilder: () => RealityCheckToneCategoryViewModel(),
      onViewModelReady: (viewModel) => viewModel.init(),
      builder: (context, viewModel, child) {
        return SafeArea(
          child: Scaffold(
            body: AppBody(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      'Select Reality Check',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please choose one of the recommended actions that you would like to perform when you hear the corresponding totem sound.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 27),
                    Expanded(
                      child: GridView.builder(
                        itemCount: viewModel.toneCategories.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemBuilder: (context, index) {
                          final toneCategory = viewModel.toneCategories[index];
                          toneCategory.isSelected = index == selectedIndex.value;
                          return InkWell(
                            onTap: () {
                              selectedIndex.value = index;
                            },
                            child: roundItem(context, toneCategory),
                          );
                        },
                      ),
                    ),
                    RealityCheckBottomBar(
                      onForwardClick: () {
                        viewModel.navigateToBedtimeScreen();
                      },
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

  Widget roundItem(BuildContext context, ToneCategory toneCategory) {
    final viewModel = context.watch<RealityCheckToneCategoryViewModel>();
    return Container(
      height: 186,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: Svg(
            imageBasePath.plus(toneCategory.isSelected
                ? 'tone_category_selected.svg'
                : 'tone_category_unselected.svg'),
          ),
          fit: BoxFit.fill,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            toneCategory.name,
            style: Theme.of(context).textTheme.bodyMediumWithFontWeight700,
          ),
          const SizedBox(height: 5),
          Text(
            toneCategory.description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(flex: 1),
          FittedBox(
            child: InkWell(
              onTap: () {
                viewModel.navigateToToneSelectionScreen(toneCategory);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: Svg(imageBasePath.plus('btn_tone_bg.svg')),
                    fit: BoxFit.fill,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image(image: Svg(imageBasePath.plus('tone_icon.svg'))),
                    const SizedBox(width: 11),
                    Text(
                      toneCategory.totemSound,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
