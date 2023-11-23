import 'package:flutter/material.dart';

class HowItScreen extends StatelessWidget {
  const HowItScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(
            flex: 3,
          ),
          Expanded(
            flex: 7,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text:
                        'Lucidity is about feeling fully awake, alert, and present in the moment.\n\nTo help you achieve this level of mental clarity, this app supports better',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  TextSpan(
                    text: ' sleep',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: ', ',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  TextSpan(
                    text: 'rest',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: ', ',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  TextSpan(
                    text: 'daytime alertness',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: ', and ',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  TextSpan(
                    text: 'dream exploration',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: '.\n\nHere’s how...',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
