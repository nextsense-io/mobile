import 'package:flutter/material.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';

import '../../../utils/utils.dart';

class BrainChecking extends StatelessWidget {
  const BrainChecking({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 6,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Image.asset(
              imageBasePath.plus("brain_check.png"),
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
                  'Brain Check',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 32),
                Text.rich(
                  TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    text: 'Use the BRAIN CHECK ',
                    children: [
                      WidgetSpan(
                        child: Image(
                          image: Svg(
                            size: const Size(19, 20.12),
                            imageBasePath.plus("brain_check.svg"),
                          ),
                        ),
                      ),
                      const TextSpan(
                          text:
                              ' feature to test your mental vigilance and how well rested you are.\n\nYou may complete a check any time, but we recommend doing it at least once per day.'),
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
