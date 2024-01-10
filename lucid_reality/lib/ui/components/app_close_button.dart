import 'package:flutter/material.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:lucid_reality/utils/utils.dart';

class AppCloseButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const AppCloseButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Image(
        image: Svg(
          imageBasePath.plus("close_button.svg"),
        ),
      ),
    );
  }
}
