import 'package:flutter/material.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:lucid_reality/ui/components/app_text_buttton.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
import 'package:lucid_reality/utils/utils.dart';

class RealityCheckBottomBar extends StatelessWidget {
  final VoidCallback? onPressed;
  final ButtonType buttonType;
  final bool progressBarVisibility;
  final double progressBarPercentage;

  const RealityCheckBottomBar(
      {super.key,
      required this.onPressed,
      this.buttonType = ButtonType.forwardArrow,
      this.progressBarVisibility = true,
      this.progressBarPercentage = 0});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(
          flex: 2,
        ),
        Flexible(
          flex: 6,
          child: progressBarVisibility
              ? LinearProgressIndicator(
                  value: progressBarPercentage,
                  backgroundColor: NextSenseColors.royalBlue,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
              : Container(),
        ),
        const SizedBox(width: 16),
        Flexible(
          flex: 2,
          child: Align(
            alignment: Alignment.centerRight,
            child: buttonType == ButtonType.forwardArrow
                ? IconButton(
                    onPressed: onPressed,
                    icon: Image(
                      image: Svg(
                        imageBasePath.plus("forward_arrow.svg"),
                      ),
                    ),
                  )
                : AppTextButton(text: "Save", onPressed: onPressed),
          ),
        )
      ],
    );
  }
}

enum ButtonType { forwardArrow, saveButton }
