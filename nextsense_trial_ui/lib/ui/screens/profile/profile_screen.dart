import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/user.dart';
import 'package:nextsense_trial_ui/flavors.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/components/clickable_zone.dart';
import 'package:nextsense_trial_ui/ui/components/emphasized_text.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_trial_ui/ui/components/rounded_background.dart';
import 'package:nextsense_trial_ui/ui/dialogs/start_adhoc_protocol_dialog.dart';
import 'package:nextsense_trial_ui/ui/dialogs/start_adhoc_survey_dialog.dart';
import 'package:nextsense_trial_ui/ui/impedance_calculation_screen.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:nextsense_trial_ui/ui/screens/auth/set_password_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/enrolled_studies/enrolled_studies_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/info/help_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/info/support_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/intro/study_intro_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/profile/profile_screen_vm.dart';
import 'package:nextsense_trial_ui/ui/screens/settings/settings_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/signal/signal_monitoring_screen.dart';
import 'package:provider/provider.dart';
import 'package:stacked/stacked.dart';

class ProfileScreen extends HookWidget {
  static const String id = 'profile_screen';

  final Navigation _navigation = getIt<Navigation>();
  final Flavor _flavor = getIt<Flavor>();

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ProfileScreenViewModel>.reactive(
      viewModelBuilder: () => ProfileScreenViewModel(),
      onModelReady: (viewModel) => viewModel.init(),
      builder: (context, ProfileScreenViewModel viewModel, child) => PageScaffold(
        showProfileButton: false,
        child: SingleChildScrollView(
          physics: ScrollPhysics(),
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
                      fontSize: 18, color: NextSenseColors.darkBlue, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              children: [
                if (_flavor.userType == UserType.researcher)
                  _MainMenuItem(
                      label: 'Switch study',
                      details: viewModel.currentStudyName ?? 'No enrolled study',
                      onPressed: () => _navigation.navigateTo(EnrolledStudiesScreen.id, pop: true)),
                if (_flavor.userType == UserType.subject)
                  _MainMenuItem(
                      label: 'Password',
                      details: 'Change Password',
                      onPressed: () {
                        _navigation.navigateTo(SetPasswordScreen.id,
                            nextRoute: NavigationRoute(pop: true));
                      }),
                _MainMenuItem(
                    label: 'Study intro',
                    onPressed: () => _navigation.navigateTo(StudyIntroScreen.id)),
                if (viewModel.isAdhocRecordingAllowed)
                  _MainMenuItem(
                      label: 'Start adhoc protocol', onPressed: () => _startAdhocProtocol(context)),
                if (viewModel.isAdhocSurveysAllowed)
                  _MainMenuItem(
                      label: 'Start adhoc survey', onPressed: () => _startAdhocSurvey(context)),
                if (_flavor.userType == UserType.researcher)
                  _MainMenuItem(
                      label: 'Check impedance',
                      onPressed: () {
                        _navigation.navigateTo(ImpedanceCalculationScreen.id);
                      }),
                if (_flavor.userType == UserType.researcher)
                  _MainMenuItem(
                      label: 'Check Signal',
                      onPressed: () {
                        _navigation.navigateTo(SignalMonitoringScreen.id);
                      }),
                if (viewModel.deviceIsConnected)
                  _MainMenuItem(
                      label: 'Disconnect',
                      onPressed: () {
                        viewModel.disconnectDevice();
                        _navigation.navigateToDeviceScan(nextRoute: NavigationRoute(pop: true));
                      })
                else
                  _MainMenuItem(
                      label: 'Connect',
                      onPressed: () {
                        _navigation.navigateToDeviceScan(nextRoute: NavigationRoute(pop: true));
                      }),
                _MainMenuItem(
                    label: 'Logout',
                    onPressed: () {
                      viewModel.logout();
                      _navigation.signOut();
                    }),
                _MainMenuItem(
                    label: 'Help',
                    onPressed: () {
                      _navigation.navigateTo(HelpScreen.id);
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
                Row(children: [SizedBox(width: 20),
                  EmphasizedText(text: 'Version ${viewModel.version ?? ''}')])
              ],
            ),
          ]),
        ),
      ),
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
    await showDialog(
        context: context,
        builder: (_) => StartAdhocProtocolDialog());
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
      padding: EdgeInsets.only(top: 10),
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
                  Image(image: Svg('assets/images/arrow_right.svg'), height: 14)
                ],
              )),
        ),
      ),
    );
  }
}
