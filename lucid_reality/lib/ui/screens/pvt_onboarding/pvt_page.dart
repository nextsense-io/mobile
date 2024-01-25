import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:lucid_reality/ui/components/app_card.dart';
import 'package:lucid_reality/utils/utils.dart';

import 'pvt_onboarding_vm.dart';

class PVTPage extends HookWidget {
  final PVTOnboardingViewModel viewModel;

  const PVTPage(this.viewModel, {super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 24),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The brain check allows you to quickly evaluate your reaction time and focus.\n\nThe test is sensitive to drowsiness and cognitive impairment, making it a great tool for measuring your mental performance at a given moment.\n\nDuring the test, simply tap the circle whenever it appears on screen.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              Image(
                width: double.maxFinite,
                image: Svg(imageBasePath.plus('pvt_onboarding.svg')),
                fit: BoxFit.fill,
              ),
              Container(
                width: 103,
                height: 103,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: Svg(imageBasePath.plus('btn_brain_check.svg')),
                    fit: BoxFit.fill,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '450ms',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
