/* A widget to display a rounded background in which other widgets can be displayed. */
import 'package:flutter/material.dart';

class RoundedBackground extends StatelessWidget {
  final Widget child;
  final double elevation;
  final double paddingPixels;
  final Border? border;
  final Gradient? gradient;

  RoundedBackground(
      {required this.child,
        this.elevation = 4,
        this.paddingPixels = 12.0,
        this.gradient,
        this.border});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.canvas,
      elevation: elevation,
      borderRadius: BorderRadius.all(Radius.circular(20)),
      shadowColor: Colors.black.withOpacity(0.3),
      surfaceTintColor: Colors.white.withOpacity(0.7),
      color: Colors.white.withOpacity(0.7),
      child: Container(
        padding: EdgeInsets.all(paddingPixels),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: border ?? Border.all(width: 0, color: Colors.black12),
          borderRadius: BorderRadius.all(Radius.circular(20)),
          gradient: gradient
        ),
        child: child,
      ),
    );
  }
}