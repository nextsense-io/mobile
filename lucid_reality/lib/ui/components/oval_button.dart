import 'package:flutter/material.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:lucid_reality/utils/utils.dart';

class OvalButton extends StatelessWidget {

  final Function onTap;
  final String text;
  final bool showBackground;

  OvalButton({Key? key, required Function onTap, String text = "", bool showBackground = false}) :
      onTap = onTap, text = text, showBackground = showBackground, super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => onTap(),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: this.showBackground ? BoxDecoration(
          image: DecorationImage(
            image: Svg(imageBasePath.plus('btn_background.svg')),
            fit: BoxFit.fill,
          ),
        ) : null,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}