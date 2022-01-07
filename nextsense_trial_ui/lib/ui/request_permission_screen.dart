import 'package:flutter/material.dart';
import 'package:nextsense_trial_ui/managers/permissions_manager.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:permission_handler/permission_handler.dart';

class RequestPermissionScreen extends StatefulWidget {
  final PermissionRequest permissionRequest;

  RequestPermissionScreen(this.permissionRequest);

  @override
  _RequestPermissionScreenState createState() =>
      _RequestPermissionScreenState(permissionRequest);
}

class _RequestPermissionScreenState extends State<RequestPermissionScreen> {
  PermissionRequest permissionRequest;

  _RequestPermissionScreenState(this.permissionRequest);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request Permission'),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
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
                            builder: (BuildContext context) {
                              return SimpleAlertDialog(
                                  title: 'Error',
                                  content: permissionRequest.deniedText!);
                            },
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
