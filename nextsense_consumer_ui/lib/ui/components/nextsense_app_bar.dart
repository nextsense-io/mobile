import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_common/ui/components/clickable_zone.dart';
import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:nextsense_consumer_ui/di.dart';
import 'package:nextsense_consumer_ui/ui/components/round_background.dart';
import 'package:nextsense_consumer_ui/ui/navigation.dart';
import 'package:nextsense_consumer_ui/ui/nextsense_colors.dart';
//import 'package:nextsense_consumer_ui/ui/screens/profile/profile_screen.dart';

// App bar at the top of the UI pages once logged in.
class NextSenseAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Navigation _navigation = getIt<Navigation>();
  final ViewModel? viewModel;
  final bool showBackButton;
  final bool showProfileButton;
  final bool showCancelButton;
  final VoidCallback? backButtonCallback;

  NextSenseAppBar(
      {super.key, this.viewModel, this.showBackButton = false, this.showProfileButton = true,
        this.showCancelButton = false, this.backButtonCallback});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 0),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          showBackButton
              ? ClickableZone(
            onTap: backButtonCallback != null
                ? () => backButtonCallback!.call()
                : () => _navigation.pop(),
            child: RoundBackground(
                color: NextSenseColors.translucentGrey,
                child:
                    SvgPicture.asset('packages/nextsense_trial_ui/assets/images/arrow_left.svg',
                        semanticsLabel: 'Back', height: 18, width: 18, fit: BoxFit.none)
            ))
              : const SizedBox.shrink(),
          const Spacer(),
          showProfileButton
              ? ClickableZone(
              child: const RoundBackground(child: Icon(Icons.person, size: 24, color: Colors.black)),
              onTap: () async => {
                //await _navigation.navigateTo(ProfileScreen.id),
                //viewModel?.notifyListeners()
              })
              : const SizedBox.shrink(),
          showCancelButton
              ? ClickableZone(onTap: backButtonCallback != null
              ? () => backButtonCallback!.call()
              : () => _navigation.pop(), child:
          const Icon(Icons.cancel, size: 40, color: NextSenseColors.red)) : const SizedBox.shrink()
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size(32, 1080);
}
