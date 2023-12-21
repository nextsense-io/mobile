import 'package:flutter/material.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:lucid_reality/utils/utils.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 6,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Image(
              image: Svg(imageBasePath.plus('onboarding_learn_bg.svg')),
              fit: BoxFit.fitWidth,
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  'Learn',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 32),
                Text.rich(
                  TextSpan(
                    text: 'Want to improve your sleep stats and brain checks? Tap the LEARN tab ',
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: [
                      WidgetSpan(
                        child: Image(
                          image: Svg(
                            imageBasePath.plus("learn.svg"),
                          ),
                        ),
                      ),
                      const TextSpan(
                          text:
                              ', for science-backed guides on napping, sleep mindset, non-sleep deep rest, and more.')
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
