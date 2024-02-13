import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
import 'package:lucid_reality/ui/screens/pvt/psychomotor_vigilance_test_vm.dart';
import 'package:lucid_reality/utils/text_theme.dart';
import 'package:lucid_reality/utils/utils.dart';

import 'package:lucid_reality/domain/psychomotor_vigilance_test.dart';


class PsychomotorVigilanceTestMainScreen extends HookWidget {
  final PsychomotorVigilanceTestViewModule viewModel;

  const PsychomotorVigilanceTestMainScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 53),
          Text(
            'Brain Check',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: ShapeDecoration(
              color: NextSenseColors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Non-sleep deep rest',
                  style: Theme.of(context).textTheme.bodySmallWithFontWeight600?.copyWith(
                        color: NextSenseColors.royalBlue,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This exercise tests your reaction time and focus. Try to complete it at least once daily to gain into your brain\'s performance and the factors that affect it.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.center,
                  child:
                  ElevatedButton(
                    onPressed: () {
                      viewModel.navigateToPVT();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: Svg(imageBasePath.plus('btn_background.svg')),
                          fit: BoxFit.fill,
                        ),
                      ),
                      child: Text(
                        'Start',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'PREVIOUS RESULTS',
            style: Theme.of(context).textTheme.bodyMediumWithFontWeight700,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemBuilder: (context, index) {
                final item = viewModel.pvtManager.getPVTResults()[index];
                return InkWell(
                  onTap: () {
                    viewModel.navigateToPVTResultsWithData(item);
                  },
                  child: _rowPVTResultItem(context, item),
                );
              },
              separatorBuilder: (context, index) {
                return const Divider(
                  thickness: 8,
                  color: Colors.transparent,
                );
              },
              itemCount: viewModel.pvtManager.getPVTResults().length,
            ),
          )
        ],
      ),
    );
  }

  Widget _rowPVTResultItem(BuildContext context, PsychomotorVigilanceTest psychomotorVigilanceTest) {
    return Container(
      height: 106,
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: NextSenseColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 82,
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(width: 1, color: NextSenseColors.royalBlue),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 37,
                  child: Text(
                    psychomotorVigilanceTest.creationDate.getDate(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMediumWithFontWeight600
                        ?.copyWith(color: NextSenseColors.skyBlue),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    psychomotorVigilanceTest.creationDate.getTime(),
                    textAlign: TextAlign.center,
                    style:
                        Theme.of(context).textTheme.bodySmallWithFontWeight600FontSize12?.copyWith(
                              color: NextSenseColors.skyBlue,
                            ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.only(left: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  psychomotorVigilanceTest.title,
                  style: Theme.of(context).textTheme.bodySmallWithFontWeight600?.copyWith(
                        color: psychomotorVigilanceTest.alertnessLevel.getColor(),
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${psychomotorVigilanceTest.averageTapLatencyMs}ms'.padLeft(5, '0'),
                  style: Theme.of(context).textTheme.bodyCaption,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
