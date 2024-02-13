import 'package:flutter/material.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:lucid_reality/utils/utils.dart';

class SvgButton extends StatelessWidget {
  final String imageName;
  final VoidCallback? onPressed;
  final Size? size;
  final EdgeInsets? padding;
  final bool showBackground;

  const SvgButton({
    super.key,
    required this.imageName,
    required this.onPressed,
    this.size,
    this.padding = EdgeInsets.zero,
    this.showBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: padding,
        decoration: this.showBackground
            ? BoxDecoration(
                image: DecorationImage(
                  image: Svg(imageBasePath.plus('btn_background.svg')),
                  fit: BoxFit.fill,
                ),
              )
            : null,
        child: Image(
          image: Svg(imageBasePath.plus(imageName)),
          height: size?.height,
          width: size?.width,
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}
