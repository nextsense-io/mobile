import 'package:flutter/material.dart';
import 'package:flutter_common/ui/components/scrollable_column.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:lucid_reality/ui/components/app_body.dart';
import 'package:lucid_reality/ui/components/app_card.dart';
import 'package:lucid_reality/ui/components/app_close_button.dart';
import 'package:lucid_reality/ui/components/reality_check_bottom_bar.dart';
import 'package:lucid_reality/ui/screens/reality_check/reality_check_time_screen_vm.dart';
import 'package:lucid_reality/utils/utils.dart';
import 'package:stacked/stacked.dart';

class RealityCheckTimeScreen extends HookWidget {
  static const String id = 'reality_check_time_screen';

  const RealityCheckTimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final numberOfReminders = useState(4);
    final startTime = useRef(DateTime.now());
    final endTime = useRef(DateTime.now().subtract(const Duration(hours: 2)));
    return ViewModelBuilder.reactive(
      viewModelBuilder: () => RealityCheckTimeScreenViewModel(),
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
                      'Reality Check',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A reality check is a method of deducing whether one is in a dream or in real life. Totem sounds will play during this interval to help you practice reality checks.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 27),
                    Flexible(flex: 5, child: AppCard(Container())),
                    const SizedBox(height: 11),
                    AppCard(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 13),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '# Daily checks',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const Spacer(flex: 1),
                          IconButton(
                            onPressed: () {
                              if (numberOfReminders.value > 1) {
                                numberOfReminders.value = numberOfReminders.value - 1;
                              }
                            },
                            icon: Image(
                              image: Svg(
                                imageBasePath.plus("btn_subtract.svg"),
                              ),
                            ),
                          ),
                          Text(
                            '${numberOfReminders.value}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          IconButton(
                            onPressed: () {
                              numberOfReminders.value = numberOfReminders.value + 1;
                            },
                            icon: Image(
                              image: Svg(
                                imageBasePath.plus("btn_plus.svg"),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 1),
                    RealityCheckBottomBar(
                      onForwardClick: () {
                        viewModel.navigateToToneCategoryScreen(
                          startTime: startTime.value,
                          endTime: endTime.value,
                          numberOfReminders: numberOfReminders.value,
                        );
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
