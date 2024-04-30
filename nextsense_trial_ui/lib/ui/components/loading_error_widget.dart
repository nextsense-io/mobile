import 'package:flutter/material.dart';
import 'package:nextsense_trial_ui/ui/components/nextsense_button.dart';

class LoadingErrorWidget extends StatelessWidget {

  final String msg;
  final VoidCallback onTap;

  const LoadingErrorWidget(this.msg, {super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: SizedBox(
        height: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(msg, textAlign: TextAlign.center),
            const SizedBox(height: 30,),
            NextsenseButton.primary("Refresh", onPressed: onTap)
          ],
        ),
      ),
    );
  }
}