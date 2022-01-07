import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/managers/session_manager.dart';

class SessionScreen extends StatefulWidget {
  @override
  _SessionScreenState createState() => _SessionScreenState();
}
class _SessionScreenState extends State<SessionScreen> {

  final SessionManager _sessionManager = GetIt.instance.get<SessionManager>();

  String? _deviceMacAddress;
  bool _loading = true;
  bool _streaming = false;
  bool _noDevice = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    List<Map<String, dynamic>> connectedDevices =
        await NextsenseBase.getConnectedDevices();
    if (connectedDevices.isNotEmpty) {
      _deviceMacAddress = connectedDevices.first[
          describeEnum(DeviceAttributesFields.macAddress)];
    } else {
      setState(() {
        _noDevice = true;
      });
    }
    setState(() {
      _loading = false;
    });
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
                padding: EdgeInsets.all(10.0),
                child: Text('Checking device...'),
                ),
          ]);
    }
    if (_noDevice) {
      return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(10.0),
              child: Text('Device is not connected.'),
            ),
          ]);
    }
    String streamButtonText = _streaming? 'Stop Recording' :'Start recording';
    return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
              padding: EdgeInsets.all(10.0),
              child: ElevatedButton(
                child: Text(streamButtonText),
                onPressed: () async {
                  if (_streaming) {
                    _sessionManager.stopSession(_deviceMacAddress!);
                  } else {
                    _sessionManager.startSession(_deviceMacAddress!);
                  }
                  setState(() {
                    _streaming = !_streaming;
                  });
                },
              )),
        ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Record a session'),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
            child: _buildBody(context)
        ),
      ),
    );
  }
}