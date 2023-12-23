import 'package:flutter/material.dart';
import 'package:flutter_common/ui/components/scrollable_column.dart';
import 'package:flutter_common/utils/android_logger.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:lucid_reality/ui/components/app_body.dart';
import 'package:lucid_reality/ui/components/app_close_button.dart';
import 'package:lucid_reality/ui/components/app_time_picker.dart';
import 'package:lucid_reality/ui/components/reality_check_bottom_bar.dart';
import 'package:lucid_reality/utils/utils.dart';
import 'package:progressive_time_picker/progressive_time_picker.dart';
import 'package:stacked/stacked.dart';

import 'reality_check_bedtime_screen_vm.dart';

class RealityCheckBedtimeScreen extends HookWidget {
  static const String id = 'reality_check_bedtime_screen';
  final CustomLogPrinter _logger = CustomLogPrinter('RealityCheckBedtimeScreen');

  RealityCheckBedtimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bedtime = useRef(DateTime.now().copyWith(hour: 0, minute: 0, second: 0));
    final wakeUpTime = useRef(bedtime.value.add(const Duration(hours: 8)));
    return ViewModelBuilder.reactive(
      viewModelBuilder: () => RealityCheckBedtimeScreenViewModel(),
      onViewModelReady: (viewModel) => viewModel.init(),
      builder: (context, viewModel, child) {
        return SafeArea(
          child: Scaffold(
            body: AppBody(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ScrollableColumn(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: AppCloseButton(
                        onPressed: () {
                          viewModel.goBack();
                        },
                      ),
                    ),
                    Text(
                      'Bedtime',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Totem sounds will play during your sleep to make you aware that you are dreaming.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 73),
                    Flexible(
                      flex: 5,
                      child: AppTimePicker(
                        startTime: PickedTime(h: bedtime.value.hour, m: bedtime.value.minute),
                        endTime: PickedTime(h: wakeUpTime.value.hour, m: wakeUpTime.value.minute),
                        onSelectionChange: (start, end, valid) {
                          bedtime.value = bedtime.value.copyWith(hour: start.h, minute: start.m);
                          wakeUpTime.value = wakeUpTime.value.copyWith(hour: end.h, minute: end.m);
                          _logger.log(Level.INFO,
                              'bedtime=>${bedtime.value.getTime()} wakeUpTime=>${wakeUpTime.value.getTime()}');
                        },
                        icon: PickerIcon.night,
                      ),
                    ),
                    const Spacer(flex: 1),
                    RealityCheckBottomBar(
                      onPressed: () {
                        viewModel.navigateToRealityCheckCompletionScreen(
                            bedtime: bedtime.value, wakeUpTime: wakeUpTime.value);
                      },
                      buttonType: ButtonType.saveButton,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
