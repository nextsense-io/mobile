import 'package:flutter/widgets.dart';
import 'package:flutter_common/ui/components/clickable_zone.dart';
import 'package:nextsense_consumer_ui/ui/nextsense_colors.dart';

// Button with muted colors that should not grab the attention too much.
class UnderlinedTextButton extends StatelessWidget {

  final String text;
  final Function onTap;

  const UnderlinedTextButton({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClickableZone(
        onTap: onTap,
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16,
            color: NextSenseColors.darkBlue, decoration: TextDecoration.underline)));
  }
}