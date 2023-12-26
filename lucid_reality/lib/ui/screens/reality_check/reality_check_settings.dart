import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucid_reality/ui/components/app_card.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
import 'package:lucid_reality/utils/text_theme.dart';
import 'package:lucid_reality/utils/utils.dart';

class RealityCheckSettings extends HookWidget {
  const RealityCheckSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CURRENT SETTINGS',
          style: Theme.of(context).textTheme.bodySmallWithFontWeight700FontSize12,
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.all(16),
          width: double.maxFinite,
          height: 81,
          decoration: BoxDecoration(
            color: NextSenseColors.cardBackground,
            image: DecorationImage(
              image: AssetImage(imageBasePath.plus('reality_check_settings_bg.png')),
              fit: BoxFit.fill,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Healing',
                style: Theme.of(context)
                    .textTheme
                    .bodySmallWithFontWeight700
                    ?.copyWith(color: NextSenseColors.skyBlue),
              ),
              SizedBox(height: 8),
              Text(
                'Manage and alleviate chronic pain ',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 1,
              child: RealityCheckSettingsWidget(
                title: 'Reality check time',
                description: '5 times\n8:00a-6:00p',
                titleColor: NextSenseColors.coral,
              ),
            ),
            SizedBox(width: 4),
            Expanded(
              flex: 1,
              child: RealityCheckSettingsWidget(
                title: 'Reality check Action',
                description: 'breathe',
                titleColor: NextSenseColors.royalPurple,
              ),
            ),
            SizedBox(width: 4),
            Expanded(
              flex: 1,
              child: RealityCheckSettingsWidget(
                title: 'Bedtime',
                description: '5 times from\n11:00a-6:00p',
                titleColor: NextSenseColors.royalBlue,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class RealityCheckSettingsWidget extends StatelessWidget {
  final String title;
  final String description;
  final Color titleColor;

  const RealityCheckSettingsWidget(
      {super.key, required this.title, required this.description, required this.titleColor});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      SizedBox(
        height: 72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .bodySmallWithFontWeight700FontSize10
                  ?.copyWith(color: titleColor),
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmallWithFontSize10,
            ),
          ],
        ),
      ),
    );
  }
}
