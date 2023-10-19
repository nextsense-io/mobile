import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_common/managers/disk_space_manager.dart';
import 'package:flutter_common/ui/components/alert.dart';
import 'package:flutter_common/ui/components/simple_button.dart';
import 'package:nextsense_consumer_ui/di.dart';
import 'package:nextsense_consumer_ui/ui/components/medium_text.dart';
import 'package:nextsense_consumer_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_consumer_ui/ui/navigation.dart';
import 'package:nextsense_consumer_ui/ui/nextsense_colors.dart';

class InsufficientSpaceScreen extends HookWidget {

  static const String id = 'insufficient_space_screen';

  final Navigation _navigation = getIt<Navigation>();
  final DiskSpaceManager _diskSpaceManager = getIt<DiskSpaceManager>();

  final Duration protocolMinDuration;

  InsufficientSpaceScreen(this.protocolMinDuration, {super.key});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(showBackButton: Navigator.of(context).canPop(), showProfileButton: false,
      child: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: MediumText(text: 'You need at least '
                  '${protocolMinDuration.inMinutes * DiskSpaceManager.mbPerMinute} Mb to store '
                  'temporary data while running your assessment. You currently have '
                  '${_diskSpaceManager.getFreeDiskSpaceMb()} Mb free.',
                  color: NextSenseColors.darkBlue),
            ),
            Padding(
                padding: const EdgeInsets.all(10.0),
                child: SimpleButton(
                  text: const MediumText(text: 'Back', color: NextSenseColors.darkBlue),
                  onTap: () async {
                    _navigation.pop();
                  },
                )
            ),
            Padding(
                padding: const EdgeInsets.all(10.0),
                child: SimpleButton(
                  text: const MediumText(text: 'Continue', color: NextSenseColors.darkBlue),
                  onTap: () async {
                    if (await _diskSpaceManager.isDiskSpaceSufficient(protocolMinDuration)) {
                      _navigation.pop();
                    } else {
                      showDialog(
                        context: context,
                        builder: (_) =>
                            const SimpleAlertDialog(
                                title: 'Warning',
                                content: 'Not enough free space to continue'),
                      );
                    }
                  },
                )
            ),
          ]),
      ),
    );
  }
}