import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/managers/permissions_manager.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/components/background_decoration.dart';
import 'package:permission_handler/permission_handler.dart';

class RequestPermissionScreen extends HookWidget {

  static const String id = 'request_permission_screen';

  final PermissionRequest permissionRequest;

  RequestPermissionScreen(this.permissionRequest);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request Permission'),
      ),
      body: Container(
        decoration: baseBackgroundDecoration,
        child: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Text(permissionRequest.requestText,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                          fontFamily: 'Roboto')),
                ),
                Padding(
                    padding: EdgeInsets.all(10.0),
                    child: ElevatedButton(
                      child: const Text('Continue'),
                      onPressed: () async {
                        await permissionRequest.permission.request();
                        if (permissionRequest.deniedText != null &&
                            await permissionRequest.permission.isDenied) {
                          showDialog(
                            context: context,
                            builder: (_) => SimpleAlertDialog(
                                  title: 'Error',
                                  content: permissionRequest.deniedText!),
                          );
                        }
                        if (!permissionRequest.required ||
                            await permissionRequest.permission.isGranted) {
                          // Navigate back to the calling screen.
                          Navigator.pop(context);
                        }
                      },
                    )),
              ]),
        ),
      ),
    );
  }
}
