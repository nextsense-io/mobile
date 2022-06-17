/* A widget to display a rounded background in which other widgets can be displayed. */
import 'package:flutter/material.dart';

class RoundedBackground extends StatelessWidget {
  final Widget child;
  final double elevation;
  final Gradient? gradient;

  RoundedBackground(
      {required this.child,
        this.elevation = 3,
        this.gradient});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: elevation,
      borderRadius: BorderRadius.all(Radius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          gradient: gradient
        ),
        child: child,
      ),
    );
  }
}