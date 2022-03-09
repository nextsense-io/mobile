import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:nextsense_base/nextsense_base.dart';

class ProtocolDebugMenu extends StatelessWidget {
  const ProtocolDebugMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String? selectedValue;
    List<String> items = [
      'Connect device',
      'Disconnect device',
    ];
    return DropdownButtonHideUnderline(
      child: DropdownButton2(
        hint: Text(
          'Debug menu',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        items: items
            .map((item) =>
            DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ))
            .toList(),
        value: selectedValue,
        onChanged: (String? value) {
          print('[TODO] ProtocolDebugMenu.build $value');
          if (value=='Connect device') {
            NextsenseBase.sendEmulatorCommand(EmulatorCommand.CONNECT);
          } else if (value == 'Disconnect device') {
            NextsenseBase.sendEmulatorCommand(EmulatorCommand.DISCONNECT);
          }
        },
        buttonHeight: 40,
        buttonWidth: 140,
        itemHeight: 40,
      ),
    );
  }
}
