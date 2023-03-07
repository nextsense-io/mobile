import 'package:flutter/material.dart';
import 'package:nextsense_trial_ui/ui/components/rounded_background.dart';

/**
 * Error overlay display on top of another page.
 */
class ErrorOverlay extends StatelessWidget {
  final Widget child;

  ErrorOverlay({required this.child});

  @override
  Widget build(BuildContext context) {
    return RoundedBackground(child: Opacity(
        opacity: 0.9,
        child: Container(height: 280, width: double.infinity, color: Colors.transparent, child: child)));
  }
}
