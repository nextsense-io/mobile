import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get_it/get_it.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/protocol.dart';
import 'package:nextsense_trial_ui/managers/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/ui/components/SessionPopScope.dart';
import 'package:nextsense_trial_ui/ui/impedance_calculation_screen.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_screen_vm.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen_vm.dart';
import 'package:nextsense_trial_ui/ui/sign_in_screen.dart';
import 'package:nextsense_trial_ui/utils/duration.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';

class DashboardScreen extends StatelessWidget {
  final AuthManager _authManager = getIt<AuthManager>();
  final DeviceManager _deviceManager = getIt<DeviceManager>();

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<DashboardScreenViewModel>.reactive(
      viewModelBuilder: () => DashboardScreenViewModel(),
      onModelReady: (viewModel) => viewModel.init(),
      builder: (context, viewModel, child) => SessionPopScope(
          child: Scaffold(
            body: Container(
              padding: EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                      child: Column(
                        children: [
                          _getDayTabs(context),
                          _buildSchedule(context),
                        ],
                      )),
                  Center(child: _buildButtons(context)),
                ],
              ),
            ),
          )),
    );
  }

  Widget _buildButtons(BuildContext context) {
    Widget checkSeatingButton = ElevatedButton(
      child: const Text('Check earbuds seating'),
      onPressed: () async {
        // Navigate to the session screen.
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ImpedanceCalculationScreen()),
        );
      },
    );
    Widget findDeviceButton = ElevatedButton(
      child: const Text('Connect your device'),
      onPressed: () async {
        // Navigate to the device scan screen.
        await Navigation.navigateToDeviceScan(
            context, /*replaceCurrent=*/ false);
      },
    );
    Widget disconnectButton = ElevatedButton(
      child: const Text('Disconnect'),
      onPressed: () async {
        _deviceManager.disconnectDevice();
        // Navigate to the device scan screen.
        Navigation.navigateToDeviceScan(context, /*replaceCurrent=*/ false);
      },
    );
    Widget logoutButton = ElevatedButton(
      child: const Text('Logout'),
      onPressed: () async {
        _deviceManager.disconnectDevice();
        _authManager.signOut();
        // Navigate to the sign-in screen.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SignInScreen()),
        );
      },
    );
    List<Widget> buttons = [];
    if (_deviceManager.getConnectedDevice() != null) {
      buttons.add(checkSeatingButton);
      buttons.add(disconnectButton);
    } else {
      buttons.add(findDeviceButton);
    }
    buttons.add(logoutButton);
    return Wrap(spacing: 5.0, children: buttons);
  }

  Widget _getDayTabs(BuildContext context) {
    final viewModel = context.watch<DashboardScreenViewModel>();
    final days = viewModel.getDays();

    return Container(
        margin: EdgeInsets.only(top: 20.0),
        height: 80.0,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: days.length,
          shrinkWrap: true,
          itemBuilder: (BuildContext context, int index) {
            DateTime day = days[index];
            final isSelected =
                viewModel.selectedDay?.isAtSameMomentAs(day) ?? false;
            final textStyle = TextStyle(
                fontSize: 20.0,
                color: isSelected ? Colors.white : Colors.black);
            return Padding(
                padding: const EdgeInsets.all(4.0),
                child: InkWell(
                  onTap: () {
                    viewModel.selectDay(day);
                  },
                  child: Container(
                      width: 60,
                      height: 80,
                      decoration: new BoxDecoration(
                          color: isSelected ? Colors.black : Colors.white,
                          borderRadius:
                          new BorderRadius.all(const Radius.circular(5.0))),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Opacity(
                              opacity: 0.5,
                              child: Text(DateFormat('MMMM').format(day),
                                  style: textStyle.copyWith(fontSize: 10.0))),
                          Opacity(
                              opacity: 0.5,
                              child: Text(DateFormat('EE').format(day),
                                  style: textStyle)),
                          Text(day.day.toString(), style: textStyle),
                        ],
                      )),
                ));
          },
        ));
  }

  Widget _buildSchedule(BuildContext context) {
    List<Protocol> protocols =
    context.watch<DashboardScreenViewModel>().getCurrentDayProtocols();

    if (protocols.length == 0) {
      return Container(
          padding: EdgeInsets.all(30.0),
          child: Text("There are no protocols for selected day",
              textAlign: TextAlign.center, style: TextStyle(fontSize: 30.0)));
    }

    return SingleChildScrollView(
      physics: ScrollPhysics(),
      child: Container(
          child: ListView.builder(
            scrollDirection: Axis.vertical,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: protocols.length,
            shrinkWrap: true,
            itemBuilder: (BuildContext context, int index) {
              Protocol protocol = protocols[index];
              var protocolBackgroundColor = Color(0xFF6DC5D5);
              switch(protocol.type) {
                case ProtocolType.variable_daytime:
                  protocolBackgroundColor = Color(0xFF6DC5D5);
                  break;
                case ProtocolType.sleep:
                case ProtocolType.eoec:
                case ProtocolType.eyes_movement:
                case ProtocolType.unknown:
                  protocolBackgroundColor = Color(0xFF984DF1);
                  break;
              }
              return Padding(
                  padding: const EdgeInsets.all(0.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 60,
                        child: Visibility(
                            visible: true,
                            child: Text(protocol.startTimeAsString,
                                style: TextStyle(color: Colors.white))),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          ProtocolScreen(protocol)));
                            },
                            child: Container(
                                padding: const EdgeInsets.all(16.0),
                                decoration: new BoxDecoration(
                                    color: protocolBackgroundColor,
                                    borderRadius: new BorderRadius.all(
                                        const Radius.circular(5.0))),
                                child: Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(protocol.getDescription(),
                                        style: TextStyle(color: Colors.white)),
                                    SizedBox(
                                      height: 8,
                                    ),
                                    Text(
                                        humanizeDuration(
                                            protocol.getMinDuration()),
                                        style: TextStyle(color: Colors.white))
                                  ],
                                )),
                          ),
                        ),
                      ),
                      Container(
                        width: 40,
                      ),
                    ],
                  ));
            },
          )),
    );
  }
}
