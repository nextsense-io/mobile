import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gson/gson.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/ui/components/scan_result_list.dart';
import 'package:nextsense_trial_ui/ui/components/search_device_bluetooth.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

class DeviceScanScreen extends StatefulWidget {
  @override
  _DeviceScanScreenState createState() => _DeviceScanScreenState();
}

class _DeviceScanScreenState extends State<DeviceScanScreen> {

  CustomLogPrinter _logger = CustomLogPrinter('DeviceScanScreen');
  Map<String, Map<String, dynamic>> _scanResults = new Map();
  bool _isScanning = false;
  bool _isLoading = false;
  int _scanningCount = 0;

  @override
  void initState() {
    _logger.log(Level.INFO, 'Initializing state.');
    super.initState();
    _startScan();
  }

  _startScan() async {
    setState(() {
      _scanResults.clear();
    });
    _logger.log(Level.INFO, 'Starting Bluetooth scan.');
    CancelListening cancel = NextsenseBase.startScanning((deviceAttributesJson) {
      Map<String, dynamic> deviceAttributes = gson.decode(deviceAttributesJson);
      String macAddress =
          deviceAttributes[describeEnum(DeviceAttributesFields.macAddress)];
      _logger.log(Level.INFO, 'Found a device: ' +
          deviceAttributes[describeEnum(DeviceAttributesFields.name)]);
      setState(() {
        _scanResults[macAddress] = deviceAttributes;
        _isScanning = false;
        _buildScanResultList();
      });
    });
    setState(() {
      _isScanning = true;
    });
  }

  _buildScanResultList() {
    return _scanResults.values
        .map((result) => ScanResultList(
        key: Key(result[result[describeEnum(DeviceAttributesFields.macAddress)]]),
        result: result,
        onTap: () => {
          // _connect(result.device),
        }))
        .toList();
  }

  _displayScanResult(resultList) {
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
                'scan',
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

  _buildBody(List<Widget> resultList) {
    Widget body = Container(
      child: Column(
        children: <Widget>[
          Expanded(
            flex: 20,
            child: Container(
              margin: EdgeInsets.only(left: 20, right: 20),
              child: Text(
                "To move ahead we need to pair the device.",
                style: Theme.of(context)
                    .textTheme
                    .headline6!
                    .copyWith(fontWeight: FontWeight.w300),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 80,
            child: _displayScanResult(resultList),
          ),
        ],
      ),
    );

    Widget progress = Container(
      child: Stack(
        children: <Widget>[
          body,
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
                    "Connecting...",
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
    return _isLoading ? progress : body;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Find your device"),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Text("Looking for NextSense devices nearby...",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                          fontFamily: 'Roboto')),
                ),
              ]),
        ),
      ),
    );
  }
}