/* Inkwell with function callback on top containing other components. */
import 'package:flutter/material.dart';

class ClickableZone extends StatelessWidget {
  final Widget child;
  final Function onTap;

  ClickableZone(
      {required this.child,
       required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap.call(),
        child: child,
    );
  }
}