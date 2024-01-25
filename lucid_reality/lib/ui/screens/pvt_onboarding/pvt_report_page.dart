import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:lucid_reality/ui/components/app_card.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
import 'package:lucid_reality/utils/text_theme.dart';
import 'package:lucid_reality/utils/utils.dart';

import 'pvt_onboarding_vm.dart';

class PVTReportPage extends HookWidget {
  final PVTOnboardingViewModel viewModel;

  const PVTReportPage(this.viewModel, {super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 24),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'At the end, you’ll get a summary of your results. Lower average times indicate greater alertness.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(height: 20),
          AppCard(
            cardBackground: NextSenseColors.deepGray,
            Image(
              image: Svg(imageBasePath.plus('pvt_onboarding_report.svg')),
              fit: BoxFit.fitWidth,
            ),
          ),
          SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...List.generate(
                viewModel.pvtReport.length * 2 - 1,
                (index) {
                  if (index.isOdd) {
                    return VerticalDivider(
                      width: 8,
                      color: Colors.transparent, // Adjust color as needed
                    );
                  } else {
                    final itemIndex = index ~/ 2;
                    final item = viewModel.pvtReport[itemIndex];
                    return Flexible(
                      child: Container(
                        height: 98,
                        padding: const EdgeInsets.all(12),
                        decoration: ShapeDecoration(
                          color: NextSenseColors.deepGray,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: Text(
                                item.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmallWithFontWeight600
                                    ?.copyWith(color: item.color),
                              ),
                            ),
                            const SizedBox(height: 5),
                            SizedBox(
                              width: double.infinity,
                              child: Text(
                                item.responseTimeInSecondsInString,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              )
            ],
          ),
        ],
      ),
    );
  }
}
