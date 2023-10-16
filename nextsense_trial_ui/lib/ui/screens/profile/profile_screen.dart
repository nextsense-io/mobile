import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/user.dart';
import 'package:nextsense_trial_ui/flavors.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:flutter_common/ui/components/clickable_zone.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_trial_ui/ui/components/rounded_background.dart';
import 'package:nextsense_trial_ui/ui/components/small_emphasized_text.dart';
import 'package:nextsense_trial_ui/ui/dialogs/start_adhoc_protocol_dialog.dart';
import 'package:nextsense_trial_ui/ui/dialogs/start_adhoc_survey_dialog.dart';
import 'package:nextsense_trial_ui/ui/impedance_calculation_screen.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:nextsense_trial_ui/ui/screens/auth/set_password_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/device_scan/device_scan_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/enrolled_studies/enrolled_studies_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/fit_test/ear_fit_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/intro/study_intro_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/profile/profile_screen_vm.dart';
import 'package:nextsense_trial_ui/ui/screens/settings/settings_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/signal/signal_monitoring_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/support/support_screen.dart';
import 'package:provider/provider.dart';
import 'package:stacked/stacked.dart';

class ProfileScreen extends HookWidget {
  static const String id = 'profile_screen';

  final Navigation _navigation = getIt<Navigation>();
  final StudyManager _studyManager = getIt<StudyManager>();
  final Flavor _flavor = getIt<Flavor>();

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();
    return ViewModelBuilder<ProfileScreenViewModel>.reactive(
      viewModelBuilder: () => ProfileScreenViewModel(),
      onModelReady: (viewModel) => viewModel.init(),
      builder: (context, ProfileScreenViewModel viewModel, child) => PageScaffold(
          showProfileButton: false,
          child: Scrollbar(
              thumbVisibility: true,
              controller: scrollController,
              child: SingleChildScrollView(
                child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                  Center(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 32, color: NextSenseColors.darkBlue),
                      ),
                      title: Text(
                        viewModel.userId ?? 'Signed out',
                        style: TextStyle(
                            fontSize: 14,
                            color: NextSenseColors.darkBlue,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  ListView(
                    padding: EdgeInsets.zero,
                    controller: scrollController,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    children: [
                      if (_flavor.userType == UserType.researcher)
                        _MainMenuItem(
                            label: 'Switch study',
                            details: viewModel.currentStudyName ?? 'No enrolled study',
                            onPressed: () async => {
                                  await _navigation.navigateTo(EnrolledStudiesScreen.id),
                                  viewModel.notifyListeners()
                                }),
                      if (_flavor.userType == UserType.subject)
                        _MainMenuItem(
                            label: 'Password',
                            details: 'Change Password',
                            onPressed: () {
                              _navigation.navigateTo(SetPasswordScreen.id,
                                  nextRoute: NavigationRoute(pop: true), arguments: false);
                            }),
                      if (_studyManager.introPageContents.isNotEmpty)
                        _MainMenuItem(
                            label: 'Study intro',
                            onPressed: () => _navigation.navigateTo(StudyIntroScreen.id)),
                      if (viewModel.isAdhocRecordingAllowed)
                        _MainMenuItem(
                            label: 'Start adhoc protocol',
                            onPressed: () => _startAdhocProtocol(context)),
                      if (viewModel.isAdhocSurveysAllowed)
                        _MainMenuItem(
                            label: 'Start adhoc survey',
                            onPressed: () => _startAdhocSurvey(context)),
                      if ((_flavor.userType == UserType.researcher ||
                          _studyManager.currentStudy!.showSignalScreens()) &&
                          viewModel.deviceIsConnected)
                        _MainMenuItem(
                            label: 'Check impedance',
                            onPressed: () {
                              _navigation.navigateTo(ImpedanceCalculationScreen.id);
                            }),
                      if ((_flavor.userType == UserType.researcher ||
                          _studyManager.currentStudy!.showSignalScreens()) &&
                          viewModel.deviceIsConnected)
                        _MainMenuItem(
                            label: 'Test ear fit',
                            onPressed: () {
                              _navigation.navigateTo(EarFitScreen.id);
                            }),
                      if ((_flavor.userType == UserType.researcher ||
                          _studyManager.currentStudy!.showSignalScreens()) &&
                          viewModel.deviceIsConnected)
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
                      SizedBox(height: 10),
                      Row(children: [
                        SizedBox(width: 20),
                        SmallEmphasizedText(text: 'Version ${viewModel.version ?? ''}')
                      ])
                    ],
                  ),
                ]),
              ))),
    );
  }

  void _startAdhocSurvey(BuildContext context) async {
    // Hide drawer
    bool? completed = await showDialog(
        context: context,
        builder: (_) => ChangeNotifierProvider.value(
            value: context.read<ProfileScreenViewModel>(), child: StartAdhocSurveyDialog()));

    if (completed != null && completed) {
      await showDialog(
        context: context,
        builder: (_) =>
            SimpleAlertDialog(title: 'Success', content: 'Survey successfully completed!'),
      );
    }
  }

  void _startAdhocProtocol(BuildContext context) async {
    await showDialog(context: context, builder: (_) => StartAdhocProtocolDialog());
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
      padding: EdgeInsets.only(top: 10, right: 20),
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
                  Image(image: Svg('packages/nextsense_trial_ui/assets/images/arrow_right.svg'), height: 14)
                ],
              )),
        ),
      ),
    );
  }
}
