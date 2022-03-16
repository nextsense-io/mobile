import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:gson/gson.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/config.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/components/scan_result_list.dart';
import 'package:nextsense_trial_ui/ui/components/search_device_bluetooth.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_screen.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

class DeviceScanScreen extends StatefulWidget {

  static const String id = 'main_screen';

  @override
  _DeviceScanScreenState createState() => _DeviceScanScreenState();
}

class _DeviceScanScreenState extends State<DeviceScanScreen> {

  final Navigation _navigation = getIt<Navigation>();
  final DeviceManager _deviceManager = getIt<DeviceManager>();
  final CustomLogPrinter _logger = CustomLogPrinter('DeviceScanScreen');

  Map<String, Map<String, dynamic>> _scanResultsMap = new Map();
  List<ScanResult> _scanResultsWidgets = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  int _scanningCount = 0;
  CancelListening? _cancelScanning;

  @override
  void initState() {
    _logger.log(Level.INFO, 'Initializing state.');
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _cancelScanning?.call();
    super.dispose();
  }

  void _startScan() async {
    setState(() {
      _scanResultsMap.clear();
    });
    _logger.log(Level.INFO, 'Starting Bluetooth scan.');
    setState(() {
      _isScanning = true;
    });
    _cancelScanning = NextsenseBase.startScanning((deviceAttributesJson) {
      Map<String, dynamic> deviceAttributes = gson.decode(deviceAttributesJson);
      String macAddress =
          deviceAttributes[describeEnum(DeviceAttributesFields.macAddress)];
      _logger.log(Level.INFO, 'Found a device: ' +
          deviceAttributes[describeEnum(DeviceAttributesFields.name)]);
      setState(() {
        _scanResultsMap[macAddress] = deviceAttributes;
        _scanResultsWidgets = _buildScanResultList();
        // This flags let the device list start getting displayed.
        _isScanning = false;

        // Connect to device automatically
        if (Config.autoConnectAfterScan) {
          _connectToDevice(deviceAttributes);
        }
      });
    });
  }

  _connectToDevice(Map<String, dynamic> result) async {
    Device device = new Device(
        result[describeEnum(DeviceAttributesFields.macAddress)],
        result[describeEnum(DeviceAttributesFields.name)]);
    _logger.log(Level.INFO, 'Connecting to device: ' + device.macAddress);
    _cancelScanning?.call();
    setState(() {
      _isConnecting = true;
    });
    try {
      bool connected = await _deviceManager.connectDevice(device);
      if (connected) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        _navigation.navigateTo(DashboardScreen.id, replace: true);
      } else {
        _onConnectionError(context);
      }
    } on PlatformException {
      _onConnectionError(context);
    }
    setState(() {
      _isConnecting = false;
    });
    _logger.log(Level.INFO, 'Connected to device: ' + device.macAddress);
  }

  Future<void> _onConnectionError(BuildContext context) async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
      return SimpleAlertDialog(
          title: 'Connection Error',
          content: 'Failed to connect to the NextSense device. Make sure '
              'it is turned on an try again. It it still fails, please '
              'contact NextSense support.');
      },
    );
    _startScan();
  }


  List<ScanResult> _buildScanResultList() {
    return _scanResultsMap.values
        .map((result) => ScanResult(
            key: Key(result[describeEnum(DeviceAttributesFields.macAddress)]),
            result: result,
            onTap: () => {
              _connectToDevice(result)
            }))
        .toList();
  }

  Widget _displayScanResults(resultList) {
    if (_isScanning) {
      setState(() {
        if (_scanningCount == 100) {
          _scanningCount = 0;
        }
        ++_scanningCount;
      });
      return SearchDeviceBluetooth(
        count: _scanningCount ~/ 25,
      );
    } else {
      return Column(
        children: <Widget>[
          Expanded(
            flex: 15,
            child: GestureDetector(
              onTap: () {
                _startScan();
              },
              child: Text(
                'Scan',
                style: Theme.of(context).textTheme.subtitle2,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 85,
            child: ListView(
              children: resultList,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildBody(List<ScanResult> resultList) {
    Widget scanningBody = Container(
      child: Column(
        children: <Widget>[
          Expanded(
            flex: 20,
            child: Padding(
              padding: EdgeInsets.all(10.0),
              child: Text('Looking for NextSense devices nearby...',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                      fontFamily: 'Roboto')),
            ),
          ),
          Expanded(
            flex: 80,
            child: _displayScanResults(resultList),
          ),
        ],
      ),
    );

    Widget connectingBody = Container(
      child: Stack(
        children: <Widget>[
          scanningBody,
          new Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Center(
                child: SizedBox(
                  height: 64,
                  width: 64,
                  child: new CircularProgressIndicator(
                    value: null,
                    strokeWidth: 12,
                  ),
                ),
              ),
              Center(
                child: Container(
                  margin: EdgeInsets.all(24),
                  child: Text(
                    'Connecting...',
                    style: Theme.of(context)
                        .textTheme
                        .bodyText2!
                        .copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
    return _isConnecting ? connectingBody : scanningBody;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find your device'),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: _buildBody(_scanResultsWidgets)
        ),
      ),
    );
  }
}