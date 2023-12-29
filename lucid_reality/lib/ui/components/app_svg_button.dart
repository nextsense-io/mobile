import 'package:flutter/material.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:lucid_reality/utils/utils.dart';

class AppSvgButton extends StatelessWidget {
  final String imageName;
  final VoidCallback? onPressed;
  final Size? size;

  const AppSvgButton({super.key, required this.imageName, required this.onPressed, this.size});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Image(
        image: Svg(imageBasePath.plus(imageName)),
        height: size?.height,
        width: size?.width,
        fit: BoxFit.fill,
      ),
    );
  }
}
