import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:intl/intl.dart' as intl;
import 'package:lucid_reality/ui/components/app_card.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
import 'package:lucid_reality/utils/text_theme.dart';
import 'package:lucid_reality/utils/utils.dart';
import 'package:progressive_time_picker/painters/time_picker_painter.dart';
import 'package:progressive_time_picker/progressive_time_picker.dart';

class AppTimePicker extends HookWidget {
  final ClockTimeFormat _clockTimeFormat = ClockTimeFormat.twelveHours;
  final PickedTime startTime;
  final PickedTime endTime;
  final PickerIcon icon;
  final SelectionChanged<PickedTime> onSelectionChange;

  AppTimePicker(
      {super.key,
      required this.startTime,
      required this.endTime,
      required this.onSelectionChange,
      this.icon = PickerIcon.non});

  @override
  Widget build(BuildContext context) {
    final startTime = useState(this.startTime);
    final endTime = useState(this.endTime);
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 23),
      Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(
                textAlign: TextAlign.center,
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'START TIME\n\n',
                      style: Theme.of(context).textTheme.bodySmallWithFontWeight700FontSize12,
                    ),
                    TextSpan(
                      text: startTime.value.getTime(),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
              Text.rich(
                textAlign: TextAlign.center,
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'END TIME\n\n',
                      style: Theme.of(context).textTheme.bodySmallWithFontWeight700FontSize12,
                    ),
                    const WidgetSpan(child: SizedBox(height: 11)),
                    TextSpan(
                      text: endTime.value.getTime(),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 32),
          TimePicker(
            height: 294,
            width: 294,
            initTime: startTime.value,
            endTime: endTime.value,
            primarySectors: _clockTimeFormat.value,
            secondarySectors: _clockTimeFormat.value * 4,
            decoration: TimePickerDecoration(
              baseColor: NextSenseColors.translucent,
              sweepDecoration: TimePickerSweepDecoration(
                pickerStrokeWidth: 6,
                useRoundedPickerCap: true,
                connectorColor: NextSenseColors.royalBlue,
                connectorStrokeWidth: 2,
                pickerColor: NextSenseColors.royalBlue,
              ),
              initHandlerDecoration: TimePickerHandlerDecoration(
                color: NextSenseColors.royalPurple,
                shape: BoxShape.circle,
                radius: 20,
                border: Border.all(color: NextSenseColors.royalBlue, width: 2),
              ),
              endHandlerDecoration: TimePickerHandlerDecoration(
                color: NextSenseColors.royalPurple,
                shape: BoxShape.circle,
                radius: 20,
                border: Border.all(color: NextSenseColors.royalBlue, width: 2),
              ),
              primarySectorsDecoration: TimePickerSectorDecoration(
                color: NextSenseColors.royalBlue,
                width: 2.0,
                size: 10,
                radiusPadding: 14.0,
              ),
              secondarySectorsDecoration: TimePickerSectorDecoration(
                color: NextSenseColors.royalBlue,
                width: 1.0,
                size: 6.0,
                radiusPadding: 10.0,
              ),
            ),
            onSelectionChange: (start, end, isDisableRange) {
              startTime.value = start;
              endTime.value = end;
              onSelectionChange(start, end, isDisableRange);
            },
            onSelectionEnd: (start, end, isDisableRange) {
              startTime.value = start;
              endTime.value = end;
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (icon == PickerIcon.night) ...[
                    Image(image: Svg(imageBasePath.plus('ic_moon.svg'))),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    getTimeInterval(init: startTime.value, end: endTime.value),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String getTimeInterval({
    required PickedTime init,
    required PickedTime end,
  }) {
    return '${end.h - init.h}h ${end.m - init.m}m';
  }
}

extension GetTime on PickedTime {
  String getTime() {
    final a = h < 12 ? 'AM' : 'PM';
    return '${intl.NumberFormat('00').format(h == 12 ? h : h % 12)}:${intl.NumberFormat('00').format(m)} $a';
  }
}

enum PickerIcon { non, day, night }
