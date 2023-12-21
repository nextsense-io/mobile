import 'package:flutter/material.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:lucid_reality/utils/utils.dart';

class SvgButton extends StatelessWidget {
  final Function onTap;
  final String svgPath;
  final bool showBackground;

  SvgButton({Key? key, required Function onTap, required String svgPath,
    bool showBackground = false}) : onTap = onTap, svgPath = svgPath,
        showBackground = showBackground, super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: this.showBackground ? BoxDecoration(
          image: DecorationImage(
            image: Svg(imageBasePath.plus('btn_background.svg')),
            fit: BoxFit.fill,
          ),
        ) : null,
        child: Image(
          image: Svg(imageBasePath.plus('backward_arrow.svg')),
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}