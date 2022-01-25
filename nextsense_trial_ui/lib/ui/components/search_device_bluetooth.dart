import 'package:flutter/material.dart';
import 'package:nextsense_trial_ui/ui/components/image_box.dart';

/* A widget to show bluetooth image while searching for the device. */
class SearchDeviceBluetooth extends StatelessWidget {
  final int count;
  SearchDeviceBluetooth({required this.count});

  @override
  Widget build(BuildContext context) {
    String path;
    switch (count) {
      case 1:
        path = 'assets/images/bluetooth_1.png';
        break;
      case 2:
        path = 'assets/images/bluetooth_2.png';
        break;
      case 3:
        path = 'assets/images/bluetooth_3.png';
        break;
      default:
        path = 'assets/images/bluetooth_1.png';
        break;
    }

    return Container(
      child: Column(
        children: <Widget>[
          Expanded(
            flex: 65,
            child: Opacity(
              opacity: 1.0,
              child: ImageBox(
                path: path,
              ),
            ),
          ),
          Expanded(
            flex: 35,
            child: Container(
              margin: EdgeInsets.only(top: 15),
              child: Text(
                'Searching for devices...',
                style: Theme.of(context).textTheme.bodyText2,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
