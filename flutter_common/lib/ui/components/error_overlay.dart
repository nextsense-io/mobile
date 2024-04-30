import 'package:flutter/material.dart';
import 'package:flutter_common/ui/components/rounded_background.dart';

/// Error overlay display on top of another page.
class ErrorOverlay extends StatelessWidget {
  final Widget child;
  final double opacity;
  final Color backgroundColor;
  final bool transparent;

  const ErrorOverlay({super.key, required this.child, this.opacity = 0.9,
    this.backgroundColor = Colors.transparent}) : transparent = opacity == 1.0;

  @override
  Widget build(BuildContext context) {
    return RoundedBackground(
        transparent: false,
        child: Opacity(
          opacity: opacity,
          child: Container(height: 280, width: double.infinity, color: backgroundColor,
              child: child)));
  }
}
