import 'package:flutter/material.dart';
import 'package:lucid_reality/ui/components/svg_button.dart';
import 'package:lucid_reality/utils/text_theme.dart';

class HomeContainer extends StatelessWidget {
  final String title;
  final Widget child;
  final bool showForwardButton;
  final VoidCallback? onForwardButtonPressed;

  const HomeContainer({
    super.key,
    required this.title,
    required this.child,
    this.showForwardButton = false,
    this.onForwardButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmallWithFontWeight700FontSize12,
            ),
            if (showForwardButton)
              SvgButton(
                padding: EdgeInsets.zero,
                onPressed: onForwardButtonPressed,
                imageName: "forward_arrow.svg",
              ),
          ],
        ),
        SizedBox(height: 8),
        child
      ],
    );
  }
}
