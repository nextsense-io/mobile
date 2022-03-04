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
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends HookWidget {

  final AuthManager _authManager = getIt<AuthManager>();
  final DeviceManager _deviceManager = getIt<DeviceManager>();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardScreenViewModel>();
    useEffect(() {
      viewModel.selectToday();
      return null;
    }, const []);

    return SessionPopScope(
        child: Scaffold(
          appBar: AppBar(
            title: Text('Dashboard'),
          ),
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 2,child: Column(
                  children: [
                    _getDayTabs(context),
                    _buildSchedule(context),
                  ],
                )),
                Expanded(flex: 1,child: _buildButtons(context)),
              ],
            ),
          ),
        ));
  }

  Widget _buildButtons(BuildContext context) {
    Widget checkSeatingButton = ElevatedButton(
      child: const Text('Check earbuds seating'),
      onPressed: () async {
        // Navigate to the session screen.
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) =>
              ImpedanceCalculationScreen()),
        );
      },
    );
    Widget findDeviceButton = ElevatedButton(
      child: const Text('Connect your device'),
      onPressed: () async {
        // Navigate to the device scan screen.
        await Navigation.navigateToDeviceScan(
            context, /*replaceCurrent=*/false);
      },
    );
    Widget disconnectButton = ElevatedButton(
      child: const Text('Disconnect'),
      onPressed: () async {
        _deviceManager.disconnectDevice();
        // Navigate to the device scan screen.
        Navigation.navigateToDeviceScan(context, /*replaceCurrent=*/false);
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
    return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: buttons);
  }

  Widget _getDayTabs(BuildContext context) {
    final viewModel = context.watch<DashboardScreenViewModel>();
    final days = viewModel.getDays();

    return Container(
        margin: EdgeInsets.symmetric(vertical: 20.0),
        height: 60.0,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: days.length,
          shrinkWrap: true,
          itemBuilder:  (BuildContext context, int index) {
            DateTime day = days[index];
            final isSelected = viewModel.selectedDay?.isAtSameMomentAs(day) ?? false;
            final textStyle = TextStyle(fontSize: 20.0, color: isSelected ? Colors.white : Colors.black);
            print(isSelected);
            return Padding(
              padding: const EdgeInsets.all(4.0),
              child: InkWell(
                onTap: (){
                  viewModel.selectDay(day);
                },
                child: Container(
                    width: 60,
                    height: 60,
                    decoration: new BoxDecoration(
                        color: isSelected ? Colors.black : Colors.white,
                        borderRadius: new BorderRadius.all(const Radius.circular(5.0))
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Opacity(opacity:0.5,child: Text(DateFormat('EE').format(day), style: textStyle)),
                        Text(day.day.toString(), style: textStyle),
                      ],
                    )
                ),
              )
            );
          },
        ));
  }


  Widget _buildSchedule(BuildContext context) {
    List<Protocol> protocols = context.watch<DashboardScreenViewModel>().getCurrentDayProtocols();
    return Container(
        margin: EdgeInsets.symmetric(vertical: 20.0),
        child: ListView.builder(
          scrollDirection: Axis.vertical,
          //physics: const NeverScrollableScrollPhysics(),
          itemCount: protocols.length,
          shrinkWrap: true,
          itemBuilder:  (BuildContext context, int index) {
            //String tag = vm.getDoctorTags()[index];
            Protocol protocol = protocols[index];
            return Padding(
                padding: const EdgeInsets.all(4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      child: Visibility(
                          visible: index == 0,
                          child: Text("08:00", style: TextStyle(color: Colors.white))
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: (){
                          Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ChangeNotifierProvider(
                                  create: (_) => new ProtocolScreenViewModel(protocol),
                                  child: ProtocolScreen(protocol))
                              ));
                        },
                        child: Container(
                            padding: const EdgeInsets.all(20.0),
                            decoration: new BoxDecoration(
                                color: Color(0xFF6DC5D5),
                                borderRadius: new BorderRadius.all(const Radius.circular(5.0))
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(protocol.getDescription(), style: TextStyle(color: Colors.white)),
                                Text(protocol.getMinDuration().inMinutes.toString() + " min.", style: TextStyle(color: Colors.white))
                              ],
                            )
                        ),
                      ),
                    ),
                    Container(
                      width: 40,
                    ),
                  ],
                )
            );
          },
        ));
  }





}