import 'package:flutter/material.dart';
import 'package:flutter_common/ui/components/scrollable_column.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucid_reality/ui/components/app_body.dart';
import 'package:lucid_reality/ui/components/app_card.dart';
import 'package:lucid_reality/ui/components/app_close_button.dart';
import 'package:lucid_reality/ui/components/reality_check_bottom_bar.dart';
import 'package:stacked/stacked.dart';

import 'reality_check_bedtime_screen_vm.dart';

class RealityCheckBedtimeScreen extends HookWidget {
  static const String id = 'reality_check_bedtime_screen';

  const RealityCheckBedtimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bedtime = useRef(DateTime.now());
    final wakeUpTime = useRef(DateTime.now().subtract(const Duration(hours: 2)));
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
                    Flexible(flex: 5, child: AppCard(Container())),
                    const Spacer(flex: 1),
                    RealityCheckBottomBar(
                      onForwardClick: () {
                        viewModel.navigateToRealityCheckCompletionScreen(
                            bedtime: bedtime.value, wakeUpTime: wakeUpTime.value);
                      },
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
