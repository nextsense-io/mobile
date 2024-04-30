import 'package:flutter/material.dart';

class SolidCircle extends StatelessWidget {
  final Color color;
  final double size;

  const SolidCircle({Key? key, required this.color, required this.size})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration:
          BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}