import 'package:flutter/material.dart';
import 'package:lucid_reality/utils/utils.dart';

class AppBody extends StatelessWidget {
  final Widget child;

  const AppBody({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            imageBasePath.plus("onboarding_bg.png"),
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: child,
    );
  }
}
