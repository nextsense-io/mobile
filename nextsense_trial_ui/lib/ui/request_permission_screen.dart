import 'package:flutter/material.dart';
import 'package:flutter_common/managers/permissions_manager.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_common/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:flutter_common/ui/components/simple_button.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:permission_handler/permission_handler.dart';

class RequestPermissionScreen extends HookWidget {
  static const String id = 'request_permission_screen';

  final PermissionRequest permissionRequest;

  RequestPermissionScreen(this.permissionRequest);

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      showBackButton: false,
      showProfileButton: false,
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Padding(
            padding: EdgeInsets.all(10.0),
            child: MediumText(text: permissionRequest.requestText, color: NextSenseColors.darkBlue),
          ),
          Padding(
              padding: EdgeInsets.all(10.0),
              child: SimpleButton(
                text: MediumText(text: 'Continue', color: NextSenseColors.darkBlue),
                onTap: () async {
                  await permissionRequest.permission.request();
                  if (permissionRequest.deniedText != null &&
                      await permissionRequest.permission.isDenied) {
                    showDialog(
                      context: context,
                      builder: (_) =>
                          SimpleAlertDialog(title: 'Error', content: permissionRequest.deniedText!),
                    );
                  }
                  if (!permissionRequest.required || await permissionRequest.permission.isGranted) {
                    // Navigate back to the calling screen.
                    Navigator.pop(context);
                  }
                },
              )),
        ]),
      ),
    );
  }
}
