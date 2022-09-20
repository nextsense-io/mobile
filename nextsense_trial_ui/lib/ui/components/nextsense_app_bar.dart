import 'package:flutter/material.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/ui/components/clickable_zone.dart';
import 'package:nextsense_trial_ui/ui/components/round_background.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:nextsense_trial_ui/ui/screens/profile/profile_screen.dart';
import 'package:nextsense_trial_ui/viewmodels/viewmodel.dart';

// App bar at the top of the UI pages once logged in.
class NextSenseAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Navigation _navigation = getIt<Navigation>();
  final ViewModel? viewModel;
  final bool showBackButton;
  final bool showProfileButton;
  final bool showCancelButton;
  final VoidCallback? backButtonCallback;

  NextSenseAppBar(
      {this.viewModel, this.showBackButton = false, this.showProfileButton = true,
        this.showCancelButton = false, this.backButtonCallback});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 0),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          showBackButton
              ? ClickableZone(
                  child: RoundBackground(
                      child:
                          Image(image: Svg('assets/images/arrow_left.svg'), height: 14, width: 14),
                      color: NextSenseColors.translucentGrey),
                  onTap: backButtonCallback != null
                      ? () => backButtonCallback!.call()
                      : () => _navigation.pop(),
                )
              : SizedBox.shrink(),
          Spacer(),
          showProfileButton
              ? ClickableZone(
                  child: RoundBackground(child: Icon(Icons.person, size: 24, color: Colors.black)),
                  onTap: () async => {
                    await _navigation.navigateTo(ProfileScreen.id),
                    viewModel?.notifyListeners()
                  })
              : SizedBox.shrink(),
          showCancelButton
              ? ClickableZone(child: Icon(Icons.cancel, size: 40, color: NextSenseColors.red),
                  onTap: backButtonCallback != null
                      ? () => backButtonCallback!.call()
                      : () => _navigation.pop()) : SizedBox.shrink()
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size(32, 1080);
}
