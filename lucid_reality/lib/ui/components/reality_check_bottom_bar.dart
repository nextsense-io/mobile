import 'package:flutter/material.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
import 'package:lucid_reality/utils/utils.dart';

class RealityCheckBottomBar extends StatelessWidget {
  final VoidCallback? onForwardClick;

  const RealityCheckBottomBar({super.key, required this.onForwardClick});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(
          flex: 2,
        ),
        const Flexible(
          flex: 6,
          child: LinearProgressIndicator(
            value: 0.2,
            backgroundColor: NextSenseColors.royalBlue,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        Flexible(
          flex: 2,
          child: Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: onForwardClick,
              icon: Image(
                image: Svg(
                  imageBasePath.plus("forward_arrow.svg"),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
