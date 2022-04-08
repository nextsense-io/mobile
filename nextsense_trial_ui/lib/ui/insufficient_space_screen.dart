import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/managers/disk_space_manager.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/components/background_decoration.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';

class InsufficientSpaceScreen extends HookWidget {

  static const String id = 'insufficient_space_screen';

  final Navigation _navigation = getIt<Navigation>();
  final DiskSpaceManager _diskSpaceManager = getIt<DiskSpaceManager>();

  final Duration protocolMinDuration;

  InsufficientSpaceScreen(this.protocolMinDuration);

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('Insufficient Space'),
      ),
      body: Container(
        decoration: baseBackgroundDecoration,
        child: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Text('You need at least ${protocolMinDuration * DiskSpaceManager.mbPerMinute}'
                      ' Mb to store temporary data while running your assessment.'
                      ' You currently have ${_diskSpaceManager.getFreeDiskSpaceMb()} Mb free.',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                          fontFamily: 'Roboto')),
                ),
                Padding(
                    padding: EdgeInsets.all(10.0),
                    child: ElevatedButton(
                      child: const Text('Back'),
                      onPressed: () async {
                        _navigation.pop();
                      },
                    )
                ),
                Padding(
                    padding: EdgeInsets.all(10.0),
                    child: ElevatedButton(
                      child: const Text('Continue'),
                      onPressed: () async {
                        if (await _diskSpaceManager.isDiskSpaceSufficient(protocolMinDuration)) {
                          _navigation.navigateToDeviceScan(replace: true);
                        } else {
                          showDialog(
                            context: context,
                            builder: (_) => SimpleAlertDialog(
                                title: 'Warning',
                                content: 'Not enough free space to continue'),
                          );
                        }
                      },
                    )
                ),
              ]),
        ),
      ),
    );
  }
}