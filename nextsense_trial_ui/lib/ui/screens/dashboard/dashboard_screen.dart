import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/protocol.dart';
import 'package:nextsense_trial_ui/domain/scheduled_protocol.dart';
import 'package:nextsense_trial_ui/domain/study_day.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/components/background_decoration.dart';
import 'package:nextsense_trial_ui/ui/components/device_state_debug_menu.dart';
import 'package:nextsense_trial_ui/ui/components/session_pop_scope.dart';
import 'package:nextsense_trial_ui/ui/main_menu.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_screen_vm.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen.dart';
import 'package:nextsense_trial_ui/utils/date_utils.dart';
import 'package:nextsense_trial_ui/utils/duration.dart';
import 'package:provider/provider.dart';
import 'package:stacked/stacked.dart';

class DashboardScreen extends StatelessWidget {

  static const String id = 'dashboard_screen';

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
                            _buildDayTabs(context),
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

  Widget _buildDayTabs(BuildContext context) {
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
            return _StudyDayCard(day);
          },
        ));
  }

  Widget _buildSchedule(BuildContext context) {
    final viewModel = context.watch<DashboardScreenViewModel>();
    List<ScheduledProtocol> scheduledProtocols = viewModel.getCurrentDayScheduledProtocols();

    if (viewModel.isBusy) {
      return CircularProgressIndicator(
        color: Colors.white,
      );
    }

    if (scheduledProtocols.length == 0) {
      return Container(
          padding: EdgeInsets.all(30.0),
          child: Column(
            children: [
              Icon(Icons.event_note, size: 50, color: Colors.white,),
              SizedBox(height: 20,),
              Text("There are no protocols for selected day",
                  textAlign: TextAlign.center, style:
                  TextStyle(fontSize: 30.0, color: Colors.white)),
            ],
          ));
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
              return _ScheduledProtocolRow(scheduledProtocol);
            },
          )),
    );
  }

}

class _StudyDayCard extends HookWidget {
  final StudyDay studyDay;
  const _StudyDayCard(this.studyDay, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardScreenViewModel>();
    final isSelected = viewModel.selectedDay == studyDay;
    final hasProtocols = viewModel.dayHasAnyScheduledProtocols(studyDay);

    useEffect(() {
      if (isSelected) {
        _ensureVisible(context);
      }
    }, []);

    final textStyle = TextStyle(
        fontSize: 20.0,
        color: isSelected ? Colors.white : Colors.black);
    return Opacity(
      opacity: hasProtocols ? 1.0 : 0.8,
      child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: InkWell(
            onTap: () {
              viewModel.selectDay(studyDay);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Container(
                  width: 65,
                  height: 80,
                  color: isSelected ? Colors.black : Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Opacity(
                        opacity: hasProtocols ? 0.5 : 0.0,
                        child: Container(
                          color: Colors.green,
                          height: 9,
                        ),
                      ),
                      SizedBox(height: 5,),
                      Opacity(
                          opacity: 0.5,
                          child: Text(DateFormat('MMMM').format(studyDay.date),
                              style: textStyle.copyWith(fontSize: 10.0))),
                      Opacity(
                          opacity: 0.5,
                          child: Text(DateFormat('EE').format(studyDay.date),
                              style: textStyle)),
                      Text(studyDay.dayNumber.toString(), style: textStyle),
                    ],
                  )),
            ),
          )),
    );
  }

  void _ensureVisible(BuildContext context) {
    Future.delayed(const Duration(milliseconds: 200)).then((value) {
      Scrollable.ensureVisible(
          context,
          alignment: 0.5,
          curve: Curves.decelerate,
          duration: const Duration(milliseconds: 160)
      );
    });
  }
}


class _ScheduledProtocolRow extends HookWidget {

  final Navigation _navigation = getIt<Navigation>();

  final ScheduledProtocol scheduledProtocol;

  _ScheduledProtocolRow(this.scheduledProtocol, {
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

    return Padding(
        padding: const EdgeInsets.all(0.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              child: Visibility(
                  visible: true,
                  child: Text(protocol.startTime.hhmm,
                      style: TextStyle(color: Colors.white))),
            ),
            Expanded(
              child: Opacity(
                opacity: scheduledProtocol.isCompleted
                    || scheduledProtocol.isSkipped ? 0.5 : 1.0,
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
        return Text("Skipped", style: TextStyle(color: Colors.white),);
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
    if (scheduledProtocol.isCompleted) {
      showDialog(
        context: context,
        builder: (_) => SimpleAlertDialog(
            title: 'Warning',
            content: 'Protocol is already completed'),
      );
      return;
    }

    if (scheduledProtocol.isSkipped) {
      showDialog(
        context: context,
        builder: (_) => SimpleAlertDialog(
            title: 'Warning',
            content: 'Cannot start protocol cause its already skipped'),
      );
      return;
    }

    if (!scheduledProtocol.isAllowedToStart()) {
      showDialog(
        context: context,
        builder: (_) => SimpleAlertDialog(
            title: 'Warning',
            content: 'This protocol can start after '
                '${scheduledProtocol.allowedStartAfter.hhmm} and before '
                '${scheduledProtocol.allowedStartBefore.hhmm}'),
      );
      return;
    }
    
    await _navigation.navigateWithCapabilityChecking(
        context,
        ProtocolScreen.id,
        arguments: scheduledProtocol
    );

    // Refresh dashboard since protocol state can be changed
    // TODO(alex): find better way to rebuild after pop
    context.read<DashboardScreenViewModel>().notifyListeners();

  }
}

