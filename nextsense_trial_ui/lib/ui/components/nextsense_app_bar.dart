import 'package:flutter/material.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/ui/components/icon_background.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:nextsense_trial_ui/ui/screens/profile/profile_screen.dart';

// App bar at the top of the UI pages once logged in.
class NextSenseAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Navigation _navigation = getIt<Navigation>();
  final bool showBackButton;
  final bool showProfileButton;

  NextSenseAppBar({this.showBackButton = false, this.showProfileButton = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: EdgeInsets.only(left: 0, right: 0, top: 6, bottom: 0),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          showBackButton
              ? RoundBackground(
                  onPressed: () => _navigation.pop(),
                  child: Image(image: Svg('assets/images/arrow_left.svg'), height: 14, width: 14),
                  color: NextSenseColors.translucentGrey)
              : SizedBox(width: 1, height: 1),
          showProfileButton
              ? RoundBackground(
                  onPressed: () => _navigation.navigateTo(ProfileScreen.id),
                  child: Icon(Icons.person, size: 24, color: Colors.black))
              : SizedBox(width: 1),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size(32, 1080);
}