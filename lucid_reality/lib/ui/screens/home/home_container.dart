import 'package:flutter/material.dart';
import 'package:lucid_reality/utils/text_theme.dart';

class HomeContainer extends StatelessWidget {
  final String title;
  final Widget child;

  const HomeContainer({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmallWithFontWeight700FontSize12,
        ),
        SizedBox(height: 8),
        child
      ],
    );
  }
}
