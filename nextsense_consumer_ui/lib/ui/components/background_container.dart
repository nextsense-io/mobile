/* A widget that contains the background decoration. */
import 'package:flutter/widgets.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';

class BackgroundContainer extends StatelessWidget {
  final Widget child;

  const BackgroundContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          image: DecorationImage(
              image: Svg("packages/nextsense_consumer_ui/assets/images/background.svg"), fit: BoxFit.cover)),
      child: child,
    );
  }
}

