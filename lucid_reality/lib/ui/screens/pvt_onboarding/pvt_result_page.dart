import 'package:flutter/material.dart';
import 'package:lucid_reality/domain/psychomotor_vigilance_test.dart';
import 'package:lucid_reality/ui/components/app_card.dart';
import 'package:lucid_reality/ui/components/app_close_button.dart';
import 'package:lucid_reality/ui/components/app_text_buttton.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
import 'package:lucid_reality/utils/text_theme.dart';
import 'package:lucid_reality/utils/utils.dart';

import 'pvt_onboarding_vm.dart';

class PVTResultPage extends StatelessWidget {
  final PVTOnboardingViewModel viewModel;

  const PVTResultPage(this.viewModel, {super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 24),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: AppCloseButton(
              onPressed: () {
                viewModel.navigateToPVTScreen();
              },
            ),
          ),
          SizedBox(height: 20),
          Text(
            'By regularly performing Brain Checks, you may learn how various factors—like sleep, diet, activity, and stress—affect your mental performance.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemBuilder: (context, index) {
                final item = viewModel.pvtResults[index];
                return _rowPVTResultItem(context, item);
              },
              separatorBuilder: (context, index) {
                return const Divider(
                  thickness: 8,
                  color: Colors.transparent,
                );
              },
              itemCount: viewModel.pvtResults.length,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Give it a try! (And don\'t worry if your first few tries are a bit slow—that’s normal 😉)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(height: 20),
          Align(
            alignment: Alignment.bottomCenter,
            child: AppTextButton(
              backgroundImage: 'btn_log_brain_check.svg',
              text: 'Log Brain Check',
              onPressed: () {
                viewModel.navigateToPVTScreen();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowPVTResultItem(
      BuildContext context, PsychomotorVigilanceTest psychomotorVigilanceTest) {
    return Container(
      height: 106,
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: NextSenseColors.deepGray,
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
