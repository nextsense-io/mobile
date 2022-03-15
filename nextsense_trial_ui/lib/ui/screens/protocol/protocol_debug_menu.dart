import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_base/nextsense_base.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/device_internal_state.dart';
import 'package:nextsense_trial_ui/managers/device_manager.dart';

enum DebugMenuItemType {
  connect,
  hdmi,
  uSd
}

class _DebugMenuItemWidget extends HookWidget {
  final DebugMenuItemType type;

  _DebugMenuItemWidget({required this.type});

  final DeviceManager _deviceManager = getIt<DeviceManager>();

  @override
  Widget build(BuildContext context) {
    final checked = useState(getInitialValue());
    var title = '';
    switch (type) {
      case DebugMenuItemType.connect:
        title = "Connect device";
        break;
      case DebugMenuItemType.hdmi:
        title = "HDMI Cable";
        break;
      case DebugMenuItemType.uSd:
        title = "microSD";
        break;
    }
    return Container(
      width: 160,
      child: CheckboxListTile(
        title: Text(title),
        value: checked.value,
        onChanged: (bool? newValue) {
          checked.value = newValue!;
          handleValueChange(newValue);
        },
        controlAffinity: ListTileControlAffinity
            .trailing, //  <-- leading Checkbox
      ),
    );
  }

  bool getInitialValue() {
    switch (type) {
      case DebugMenuItemType.connect:
        return _deviceManager.deviceState.value == DeviceState.READY;
      case DebugMenuItemType.hdmi:
        return _deviceManager.isHdmiCablePresent;
      case DebugMenuItemType.uSd:
        return _deviceManager.isUSdPresent;
    }
    return true;
  }

  void handleValueChange(bool value) {
    switch (type) {
      case DebugMenuItemType.connect:
        if (value) {
          NextsenseBase.sendEmulatorCommand(EmulatorCommand.CONNECT);
        } else {
          NextsenseBase.sendEmulatorCommand(EmulatorCommand.DISCONNECT);
        }
        break;
      case DebugMenuItemType.hdmi:
        _sendStateChangeCommand({
          DeviceInternalStateFields.hdmiCablePresent.name : value
        });

        break;
      case DebugMenuItemType.uSd:
        _sendStateChangeCommand({
          DeviceInternalStateFields.uSdPresent.name : value
        });
        break;
    }
  }

  void _sendStateChangeCommand(Map<String, dynamic> params) {
    NextsenseBase.sendEmulatorCommand(EmulatorCommand.INTERNAL_STATE_CHANGE,
      params: params);
  }
}

class ProtocolDebugMenu extends StatelessWidget {
  const ProtocolDebugMenu({Key? key}) : super(key: key);

  static const List<DebugMenuItemType> items = DebugMenuItemType.values;

  @override
  Widget build(BuildContext context) {
    return _dropdown(context);
  }

  Widget _dropdown(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        customButton: const Icon(
          Icons.settings_applications,
          size: 30,
          color: Colors.white,
        ),
        hint: Text(
          'Debug menu',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        items:
        items.map(
              (type) =>
              DropdownMenuItem<String>(
                value: "",
                child: _DebugMenuItemWidget(type: type),
              ),
        ).toList(),
        onChanged: (value) {},
        itemHeight: 48,
        dropdownElevation: 8,
        dropdownWidth: 200,
      ),
    );
  }
}