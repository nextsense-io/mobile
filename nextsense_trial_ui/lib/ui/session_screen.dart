import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/managers/session_manager.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

class SessionScreen extends StatefulWidget {
  @override
  _SessionScreenState createState() => _SessionScreenState();
}
class _SessionScreenState extends State<SessionScreen> {

  final SessionManager _sessionManager = GetIt.instance.get<SessionManager>();
  final CustomLogPrinter _logger = CustomLogPrinter('SessionScreen');

  String? _deviceMacAddress;
  bool _loading = true;
  bool _streaming = false;
  bool _noDevice = false;
  CancelListening? _cancelListening;

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    _cancelListening?.call();
    super.dispose();
  }

  void init() async {
    List<Map<String, dynamic>> connectedDevices =
        await NextsenseBase.getConnectedDevices();
    if (connectedDevices.isNotEmpty) {
      _deviceMacAddress = connectedDevices.first[
          describeEnum(DeviceAttributesFields.macAddress)];
      _listenToState();
    } else {
      setState(() {
        _noDevice = true;
      });
    }
    setState(() {
      _loading = false;
    });
  }

  void _listenToState() {
    _cancelListening = NextsenseBase.listenToDeviceState((newDeviceState) {
      String deviceState = newDeviceState;
      _logger.log(Level.INFO, 'Device state changed to ' + deviceState);
    }, _deviceMacAddress!);
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
    String streamButtonText = _streaming ? 'Stop Recording' : 'Start recording';
    return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
              padding: EdgeInsets.all(10.0),
              child: ElevatedButton(
                child: Text(streamButtonText),
                onPressed: () async {
                  try {
                    if (_streaming) {
                      await _sessionManager.stopSession(_deviceMacAddress!);
                    } else {
                      await _sessionManager.startSession(_deviceMacAddress!);
                    }
                    setState(() {
                      _streaming = !_streaming;
                    });
                  } catch (e) {
                    String startOrStop = _streaming ? 'stop' : 'start';
                    await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return SimpleAlertDialog(
                            title: 'Error',
                            content: 'Failed to ${startOrStop}. Make sure your '
                                'device is nearby and you have a working '
                                'internet connection');
                      },
                    );
                  }
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