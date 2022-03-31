import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/protocol.dart';
import 'package:nextsense_trial_ui/domain/scheduled_protocol.dart';
import 'package:nextsense_trial_ui/domain/study_day.dart';
import 'package:nextsense_trial_ui/managers/connectivity_manager.dart';
import 'package:nextsense_trial_ui/ui/check_internet_screen.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/components/background_decoration.dart';
import 'package:nextsense_trial_ui/ui/components/device_state_debug_menu.dart';
import 'package:nextsense_trial_ui/ui/components/session_pop_scope.dart';
import 'package:nextsense_trial_ui/ui/main_menu.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_screen_vm.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen.dart';
import 'package:nextsense_trial_ui/utils/duration.dart';
import 'package:provider/provider.dart';
import 'package:stacked/stacked.dart';

class DashboardScreen extends StatelessWidget {

  static const String id = 'dashboard_screen';

  final Navigation _navigation = getIt<Navigation>();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<DashboardScreenViewModel>.reactive(
      viewModelBuilder: () => DashboardScreenViewModel(),
      onModelReady: (viewModel) => viewModel.init(),
      builder: (context, viewModel, child) => SessionPopScope(
          child: SafeArea(
            child: Scaffold(
              key: _scaffoldKey,
              drawer: MainMenu(),
              body: Container(
                padding: EdgeInsets.only(bottom: 10.0, left: 10.0, right: 10.0),
                decoration: baseBackgroundDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                        child: Column(
                          children: [
                            _appBar(context),
                            _getDayTabs(context),
                            _buildSchedule(context),
                          ],
                        )),
                  ],
                ),
              ),
            ),
          )),
    );
  }

  Widget _appBar(BuildContext context) {
    final viewModel = context.watch<DashboardScreenViewModel>();
    return Container(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.menu,
              size: 30,
              color: Colors.white,
            ),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          Row(
            children: [
              _indicator("HDMI", viewModel.isHdmiCablePresent),
              SizedBox(width: 10,),
              _indicator("Micro SD", viewModel.isUSdPresent),
              SizedBox(width: 10,),
              DeviceStateDebugMenu(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _indicator(String text, bool on) {
    return Opacity(
      opacity: on ? 1.0 : 0.3,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white)
        ),
        padding: EdgeInsets.all(5.0),
        child: Text(
            text + (on ? " ON" : " OFF"),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _getDayTabs(BuildContext context) {
    final viewModel = context.watch<DashboardScreenViewModel>();
    List<StudyDay> days = viewModel.getDays();

    return Container(
        height: 80.0,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: days.length,
          shrinkWrap: true,
          itemBuilder: (BuildContext context, int index) {
            StudyDay day = days[index];
            final isSelected = viewModel.selectedDay == day;
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
                              child: Text(DateFormat('MMMM').format(day.date),
                                  style: textStyle.copyWith(fontSize: 10.0))),
                          Opacity(
                              opacity: 0.5,
                              child: Text(DateFormat('EE').format(day.date),
                                  style: textStyle)),
                          Text(day.dayNumber.toString(), style: textStyle),
                        ],
                      )),
                ));
          },
        ));
  }

  Widget _buildSchedule(BuildContext context) {
    List<ScheduledProtocol> scheduledProtocols =
        context.watch<DashboardScreenViewModel>().getCurrentDayScheduledProtocols();

    if (scheduledProtocols.length == 0) {
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
            itemCount: scheduledProtocols.length,
            shrinkWrap: true,
            itemBuilder: (BuildContext context, int index) {
              ScheduledProtocol scheduledProtocol = scheduledProtocols[index];
              return ScheduledProtocolRow(scheduledProtocol);
            },
          )),
    );
  }

}

class ScheduledProtocolRow extends HookWidget {

  final Navigation _navigation = getIt<Navigation>();

  final ScheduledProtocol scheduledProtocol;

  ScheduledProtocolRow(this.scheduledProtocol, {
    Key? key,}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Protocol protocol = scheduledProtocol.protocol;
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

    String startTimeString = DateFormat('HH:mm')
        .format(protocol.startTime);

    return Padding(
        padding: const EdgeInsets.all(0.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              child: Visibility(
                  visible: true,
                  child: Text(startTimeString,
                      style: TextStyle(color: Colors.white))),
            ),
            Expanded(
              child: Opacity(
                opacity: scheduledProtocol.isCompleted ? 0.5 : 1.0,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: InkWell(
                    onTap: () {
                      _onProtocolClicked(context, scheduledProtocol);
                    },
                    child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: new BoxDecoration(
                            color: protocolBackgroundColor,
                            borderRadius: new BorderRadius.all(
                                const Radius.circular(5.0))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(protocol.description,
                                    style: TextStyle(color: Colors.white)),
                                SizedBox(
                                  height: 8,
                                ),
                                Text(
                                    humanizeDuration(
                                        protocol.minDuration),
                                    style: TextStyle(color: Colors.white))
                              ],
                            ),
                            _protocolState(scheduledProtocol)
                          ],
                        )),
                  ),
                ),
              ),
            ),
            Container(
              width: 40,
            ),
          ],
        ));
  }
  Widget _protocolState(ScheduledProtocol scheduledProtocol) {
    switch(scheduledProtocol.state) {
      case ProtocolState.skipped:
        return Text("Cancelled", style: TextStyle(color: Colors.white),);
      case ProtocolState.cancelled:
        return Text("Cancelled", style: TextStyle(color: Colors.white),);
      case ProtocolState.completed:
        return Icon(Icons.check_circle, color: Colors.white);
      default: break;
    }
    return Container();
  }

  void _onProtocolClicked(BuildContext context,
      ScheduledProtocol scheduledProtocol) async {
    Protocol protocol = scheduledProtocol.protocol;
    if (scheduledProtocol.isCompleted) {
      showDialog(
        context: context,
        builder: (_) => SimpleAlertDialog(
            title: 'Warning',
            content: 'Protocol is already completed'),
      );
      return;
    }
    
    await _navigation.navigateWithConnectionChecking(
        context,
        ProtocolScreen.id,
        arguments: scheduledProtocol
    );

    // Refresh dashboard since protocol state can be changed
    // TODO(alex): find better way to rebuild after pop
    context.read<DashboardScreenViewModel>().notifyListeners();

  }
}

