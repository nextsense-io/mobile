import 'package:flutter/material.dart';

/* A widget to display image. */
class ImageBox extends StatelessWidget {
  final String path;
  final double marginTop;
  final double marginRight;
  final double marginLeft;
  final double marginBottom;
  final BoxFit boxFit;
  ImageBox(
      {required this.path,
       this.marginTop = 0,
       this.marginRight = 0,
       this.marginBottom = 0,
       this.marginLeft = 0,
       this.boxFit = BoxFit.fill});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        top: marginTop,
        right: marginRight,
        left: marginLeft,
        bottom: marginBottom,
      ),
      child: Image.asset(
        path,
        fit: boxFit,
      ),
    );
  }
}