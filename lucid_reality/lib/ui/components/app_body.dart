import 'package:flutter/material.dart';
import 'package:lucid_reality/ui/components/app_circular_progress_indicator.dart';
import 'package:lucid_reality/utils/utils.dart';

class AppBody extends StatelessWidget {
  final Widget child;
  final bool isLoading;

  const AppBody({super.key, required this.child, this.isLoading = false});

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
      child: isLoading ? AppCircleProgressIndicator() : child,
    );
  }
}
