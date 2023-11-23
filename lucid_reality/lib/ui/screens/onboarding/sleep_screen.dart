import 'package:flutter/material.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:lucid_reality/utils/utils.dart';

class SleepScreen extends StatelessWidget {
  const SleepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: 0,
          left: 0,
          top: 120,
          child: Image.asset(
            alignment: Alignment.bottomCenter,
            imageBasePath.plus("onboarding_sleep_bg.png"),
            fit: BoxFit.fitWidth,
          ),
        ),
        Column(
          children: [
            const Expanded(
              flex: 6,
              child: SizedBox.shrink(),
            ),
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      'Sleep',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 32),
                    Text.rich(
                      TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium,
                        text: 'In the SLEEP tab ',
                        children: [
                          WidgetSpan(
                            child: Image(
                              image: Svg(imageBasePath.plus('sleep.svg'), size: const Size(25, 20)),
                            ),
                          ),
                          const TextSpan(
                              text:
                                  ' , you\'ll find a summary of your sleep trends.\n\nCompare this to your brain checks to find out how your sleep affects your mental performance.')
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
