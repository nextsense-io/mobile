/* A widget that contains the background decoration. */
import 'package:flutter/widgets.dart';

class BackgroundContainer extends StatelessWidget {
  final Widget child;

  BackgroundContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          image: DecorationImage(
              image: AssetImage("assets/images/dashboard_background.png"), fit: BoxFit.cover)),
      child: child,
    );
  }
}

