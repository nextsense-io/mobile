import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/ui/components/header_text.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_trial_ui/ui/components/simple_button.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/device_scan/device_scan_screen.dart';

class PrepareDeviceScreen extends HookWidget {

  static const String id = 'prepare_device_screen';

  final Navigation _navigation = getIt<Navigation>();

  @override
  Widget build(BuildContext context) {
    return PageScaffold(showBackButton: false, showProfileButton: false, child: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              HeaderText(text: 'Device Setup'),
              Image(image: AssetImage('assets/images/xenon.png')),
              Padding(
                padding: EdgeInsets.all(20.0),
                child: MediumText(text:
                    'Turn the device on by sliding the power button from “OFF” to “ON” as shown.',
                color: NextSenseColors.darkBlue)),
              Padding(
                  padding: EdgeInsets.all(10.0),
                  child: SimpleButton(
                    text: MediumText(text: 'Continue', color: NextSenseColors.purple),
                    onTap: () async {
                      _navigation.navigateTo(DeviceScanScreen.id, replace: true,
                          nextRoute: NavigationRoute(routeName: DashboardScreen.id, replace: true));
                    },
                  )),
            ]),
      ),
    );
  }
}