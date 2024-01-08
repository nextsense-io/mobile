import 'package:flutter/material.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:lucid_reality/utils/utils.dart';

class SvgButton extends StatelessWidget {
  final String imageName;
  final VoidCallback? onPressed;
  final Size? size;
  final EdgeInsets? padding;

  const SvgButton({
    super.key,
    required this.imageName,
    required this.onPressed,
    this.size,
    this.padding = EdgeInsets.zero
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: padding,
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
