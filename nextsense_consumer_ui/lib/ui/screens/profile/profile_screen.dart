import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:flutter_common/ui/components/clickable_zone.dart';
import 'package:flutter_common/ui/components/rounded_background.dart';
import 'package:nextsense_consumer_ui/di.dart';
import 'package:nextsense_consumer_ui/ui/components/medium_text.dart';
import 'package:nextsense_consumer_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_consumer_ui/ui/components/small_emphasized_text.dart';
import 'package:nextsense_consumer_ui/ui/navigation.dart';
import 'package:nextsense_consumer_ui/ui/nextsense_colors.dart';
import 'package:nextsense_consumer_ui/ui/screens/device_scan/device_scan_screen.dart';
import 'package:nextsense_consumer_ui/ui/screens/fit_test/ear_fit_screen.dart';
import 'package:nextsense_consumer_ui/ui/screens/impedance_calculation_screen.dart';
import 'package:nextsense_consumer_ui/ui/screens/profile/profile_screen_vm.dart';
import 'package:nextsense_consumer_ui/ui/screens/settings/settings_screen.dart';
import 'package:nextsense_consumer_ui/ui/screens/signal/signal_monitoring_screen.dart';
import 'package:nextsense_consumer_ui/ui/screens/support/support_screen.dart';
import 'package:stacked/stacked.dart';

class ProfileScreen extends HookWidget {
  static const String id = 'profile_screen';

  final Navigation _navigation = getIt<Navigation>();

  ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();
    return ViewModelBuilder<ProfileScreenViewModel>.reactive(
      viewModelBuilder: () => ProfileScreenViewModel(),
      onViewModelReady: (viewModel) => viewModel.init(),
      builder: (context, ProfileScreenViewModel viewModel, child) => PageScaffold(
          showProfileButton: false,
          child: Scrollbar(
              thumbVisibility: true,
              controller: scrollController,
              child: SingleChildScrollView(
                child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                  Center(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 32, color: NextSenseColors.darkBlue),
                      ),
                      title: Text(
                        viewModel.userId ?? 'Signed out',
                        style: const TextStyle(
                            fontSize: 14,
                            color: NextSenseColors.darkBlue,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ListView(
                    padding: EdgeInsets.zero,
                    controller: scrollController,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      if (viewModel.deviceIsConnected)
                        _MainMenuItem(
                            label: 'Check impedance',
                            onPressed: () {
                              _navigation.navigateTo(ImpedanceCalculationScreen.id);
                            }),
                      if (viewModel.deviceIsConnected)
                        _MainMenuItem(
                            label: 'Test ear fit',
                            onPressed: () {
                              _navigation.navigateTo(EarFitScreen.id);
                            }),
                        _MainMenuItem(
                            label: 'Check Signal',
                            onPressed: () {
                              _navigation.navigateTo(SignalMonitoringScreen.id);
                            }),
                      if (viewModel.deviceIsConnected)
                        _MainMenuItem(
                            label: 'Disconnect',
                            onPressed: () async {
                              await viewModel.disconnectDevice();
                              await _navigation.navigateTo(DeviceScanScreen.id,
                                  nextRoute: NavigationRoute(pop: true));
                              viewModel.refresh();
                            })
                      else
                        _MainMenuItem(
                            label: 'Connect',
                            onPressed: () async {
                              await _navigation.navigateTo(DeviceScanScreen.id,
                                  nextRoute: NavigationRoute(pop: true));
                              viewModel.refresh();
                            }),
                      _MainMenuItem(
                          label: 'Logout',
                          onPressed: () {
                            viewModel.logout();
                            _navigation.signOut();
                          }),
                      _MainMenuItem(
                          label: 'Settings',
                          onPressed: () {
                            _navigation.navigateTo(SettingsScreen.id);
                          }),
                      _MainMenuItem(
                          label: 'Contact Support',
                          onPressed: () {
                            _navigation.navigateTo(SupportScreen.id);
                          }),
                      const SizedBox(height: 10),
                      Row(children: [
                        const SizedBox(width: 20),
                        SmallEmphasizedText(text: 'Version ${viewModel.version ?? ''}')
                      ])
                    ],
                  ),
                ]),
              ))),
    );
  }
}

class _MainMenuItem extends StatelessWidget {
  final String label;
  final String? details;
  final VoidCallback onPressed;

  const _MainMenuItem({
    Key? key,
    required this.label,
    required this.onPressed,
    this.details,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, right: 20),
      child: ClickableZone(
        onTap: () => onPressed.call(),
        child: RoundedBackground(
          child: Padding(
              padding: const EdgeInsets.only(
                top: 10,
                bottom: 10,
                left: 15,
                right: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                    MediumText(text: label, color: NextSenseColors.darkBlue),
                    if (details != null) MediumText(text: details!)
                  ]),
                  const Image(image:
                  Svg('packages/nextsense_trial_ui/assets/images/arrow_right.svg'), height: 14)
                ],
              )),
        ),
      ),
    );
  }
}
