import 'package:flutter/material.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:nextsense_trial_ui/ui/components/rounded_background.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';

class ProtocolStepCard extends StatelessWidget {
  final ImageProvider image;
  final String text;
  final bool currentStep;

  ProtocolStepCard({required this.image, required this.text, this.currentStep = false});

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 80,
        child: Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          child: RoundedBackground(
              child: Row(children: [
            SizedBox(width: 30),
            Opacity(opacity: currentStep ? 1.0 : 0.1, child: Image(image: image, width: 40)),
            SizedBox(width: 20),
            Opacity(
                opacity: currentStep ? 1.0 : 0.1,
                child: MediumText(text: text, color: NextSenseColors.darkBlue))
          ])),
        ));
  }
}
