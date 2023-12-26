import 'package:flutter/material.dart';
import 'package:flutter_common/ui/components/scrollable_column.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
import 'package:lucid_reality/ui/screens/lucid/lucid_screen_vm.dart';
import 'package:lucid_reality/ui/screens/reality_check/reality_check_settings.dart';
import 'package:lucid_reality/utils/text_theme.dart';
import 'package:lucid_reality/utils/utils.dart';
import 'package:stacked/stacked.dart';

class LucidScreen extends HookWidget {
  const LucidScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder.reactive(
      viewModelBuilder: () => LucidScreenViewModel(),
      onViewModelReady: (viewModel) => viewModel.init(),
      builder: (context, viewModel, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ScrollableColumn(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lucid Dreaming',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              Text(
                'JOURNAL',
                style: Theme.of(context).textTheme.bodySmallWithFontWeight700FontSize12,
              ),
              const SizedBox(height: 5),
              InkWell(
                onTap: () {
                  if (viewModel.isRealitySettingsCompleted()) {
                    viewModel.navigateToDreamJournalScreen();
                  } else {
                    viewModel.navigateToCategoryScreen();
                  }
                },
                child: Container(
                  width: double.maxFinite,
                  height: 137,
                  decoration: ShapeDecoration(
                    color: NextSenseColors.cardBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Flexible(
                        flex: 6,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dream Journal',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmallWithFontWeight600
                                    ?.copyWith(color: NextSenseColors.royalPurple),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'A collection of all your recorded dreams.',
                                style: Theme.of(context).textTheme.bodyCaption,
                              )
                            ],
                          ),
                        ),
                      ),
                      Flexible(
                        flex: 4,
                        child: Image(
                          image: Svg(imageBasePath.plus('dream_journal.svg')),
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (viewModel.isRealitySettingsCompleted()) RealityCheckSettings(),
            ],
          ),
        );
      },
    );
  }
}
