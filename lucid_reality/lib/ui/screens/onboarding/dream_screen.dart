import 'package:flutter/material.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';

import 'package:lucid_reality/utils/utils.dart';

class DreamScreen extends StatelessWidget {
  const DreamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 6,
          child: Image.asset(
            imageBasePath.plus('onboarding_dream_bg.png'),
            fit: BoxFit.fitWidth,
          ),
        ),
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  'Dream',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 32),
                Text.rich(
                  TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    text: 'Extend lucidity into the night by tapping the DREAM tab ',
                    children: [
                      WidgetSpan(
                        child: Image(
                          image: Svg(imageBasePath.plus('lucid.svg')),
                        ),
                      ),
                      const TextSpan(
                        text:
                            '. Here you\'ll find a dream journal and tools to help you start lucid dreaming.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
