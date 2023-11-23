import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'onboarding_screen_vm.dart';

class LetsGoScreen extends StatelessWidget {
  const LetsGoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder.reactive(
        viewModelBuilder: () => OnboardingScreenViewModel(),
        onViewModelReady: (viewModel) => viewModel.init(),
        builder: (context, viewModel, child) {
          return Column(
            children: [
              const Expanded(flex: 4, child: SizedBox.shrink()),
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'Time to get Lucid.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Start your journey now by logging your first brain check.',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(width: 1, color: Color(0xFF7336BA)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () {
                          viewModel.redirectToDashboard();
                        },
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: ShapeDecoration(
                            gradient: const RadialGradient(
                              center: Alignment(0.07, 0.78),
                              radius: 0,
                              colors: [Color(0xE09E1FF6), Color(0x386D2F98)],
                            ),
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(width: 1, color: Color(0xFF7336BA)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Let’s go!',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          );
        });
  }
}
