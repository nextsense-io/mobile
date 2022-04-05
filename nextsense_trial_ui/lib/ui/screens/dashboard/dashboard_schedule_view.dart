
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/protocol.dart';
import 'package:nextsense_trial_ui/domain/scheduled_protocol.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_screen_vm.dart';
import 'package:nextsense_trial_ui/ui/screens/protocol/protocol_screen.dart';
import 'package:nextsense_trial_ui/utils/date_utils.dart';
import 'package:nextsense_trial_ui/utils/duration.dart';
import 'package:provider/src/provider.dart';

class DashboardScheduleView extends StatelessWidget {
  const DashboardScheduleView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardScreenViewModel>();
    List<ScheduledProtocol> scheduledProtocols = viewModel.getCurrentDayScheduledProtocols();

    if (viewModel.isBusy) {
      return Center(
        child: Container(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            color: Colors.deepPurple,
          ),
        ),
      );
    }

    if (scheduledProtocols.length == 0) {
      return Container(
          padding: EdgeInsets.all(30.0),
          child: Column(
            children: [
              Icon(Icons.event_note, size: 50, color: Colors.grey,),
              SizedBox(height: 20,),
              Text("There are no protocols for selected day",
                  textAlign: TextAlign.center, style:
                  TextStyle(fontSize: 30.0, color: Colors.grey)),
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
        protocolBackgroundColor = Color(0xFF82C3D3);
        break;
      case ProtocolType.sleep:
        protocolBackgroundColor = Color(0xFF984DF1);
        break;
      case ProtocolType.eoec:
      case ProtocolType.eyes_movement:
      case ProtocolType.unknown:
        protocolBackgroundColor = Color(0xFFE6AEA0);
        break;
    }

    return Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              child: Visibility(
                  visible: true,
                  child: Text(protocol.startTime.hhmm,
                      style: TextStyle(color: Colors.black))),
            ),
            Expanded(
              child: Opacity(
                opacity: scheduledProtocol.isCompleted
                    || scheduledProtocol.isSkipped ? 0.8 : 1.0,
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