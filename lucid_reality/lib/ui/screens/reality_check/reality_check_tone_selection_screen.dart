import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:lucid_reality/domain/tone_category.dart';
import 'package:lucid_reality/ui/components/app_body.dart';
import 'package:lucid_reality/ui/components/app_card.dart';
import 'package:lucid_reality/ui/components/app_close_button.dart';
import 'package:lucid_reality/ui/components/reality_check_bottom_bar.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
import 'package:lucid_reality/ui/screens/reality_check/reality_check_tone_category_vm.dart';
import 'package:lucid_reality/utils/utils.dart';
import 'package:stacked/stacked.dart';

import 'reality_check_tone_selection_vm.dart';

class RealityCheckToneSelectionScreen extends HookWidget {
  static const String id = 'reality_check_tone_selection_screen';

  const RealityCheckToneSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedIndex = useState(0);
    final isStartForResult = useState(false);
    return ViewModelBuilder.reactive(
      viewModelBuilder: () => RealityCheckToneSelectionViewModel(),
      onViewModelReady: (viewModel) {
        viewModel.init();
        Future.delayed(Duration(milliseconds: 100), () {
          var dataSet = ModalRoute.of(context)?.settings.arguments;
          if (dataSet is Map) {
            var totemSound = dataSet[totemSoundKey];
            var index = viewModel.toneList.indexWhere((element) => element.tone == totemSound);
            if (index != -1) {
              selectedIndex.value = index;
            }
            isStartForResult.value = dataSet[isStartForResultKey];
          }
        });
      },
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
                      'Select Reality Check Tone',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please choose the sound you would like to be played as a reminder to do a reality check.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 30),
                    Expanded(
                      child: AppCard(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        Scrollbar(
                          trackVisibility: true,
                          thumbVisibility: true,
                          child: ListView.separated(
                            itemBuilder: (context, index) {
                              final tone = viewModel.toneList[index];
                              tone.isSelected = selectedIndex.value == index;
                              return InkWell(
                                onTap: () {
                                  selectedIndex.value = index;
                                  viewModel.playMusic(tone.musicFile);
                                },
                                child: rowToneListItem(context, tone),
                              );
                            },
                            separatorBuilder: (context, index) => const Divider(
                              thickness: 1,
                              color: NextSenseColors.translucent,
                            ),
                            itemCount: viewModel.toneList.length,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    RealityCheckBottomBar(
                      progressBarVisibility: !isStartForResult.value,
                      progressBarPercentage: 0.80,
                      onPressed: () {
                        viewModel.goBack();
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

  Widget rowToneListItem(BuildContext context, Tone tone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              tone.tone,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          tone.isSelected
              ? Image(
                  image: Svg(imageBasePath.plus('ic_right_white.svg')),
                  width: 20,
                )
              : const SizedBox.shrink()
        ],
      ),
    );
  }
}
