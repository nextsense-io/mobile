import 'package:flutter/material.dart';

class WhiteThemeOverride extends StatelessWidget {
  final Widget child;

  const WhiteThemeOverride(this.child);

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return Theme(
        child: child,
        data: themeData.copyWith(
          scaffoldBackgroundColor: Colors.white,
        ));
  }
}