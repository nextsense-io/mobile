import 'package:flutter/material.dart';
import 'package:flutter_common/ui/components/scrollable_column.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucid_reality/domain/lucid_reality_category.dart';
import 'package:lucid_reality/ui/components/app_body.dart';
import 'package:lucid_reality/ui/components/app_close_button.dart';
import 'package:lucid_reality/ui/components/reality_check_bottom_bar.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
import 'package:lucid_reality/ui/screens/reality_check/set_goal_vm.dart';
import 'package:lucid_reality/utils/text_theme.dart';
import 'package:stacked/stacked.dart';

class SetGoalScreen extends HookWidget {
  static const String id = 'set_goal_screen';

  const SetGoalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isStartForResult = (ModalRoute.of(context)?.settings.arguments is bool
        ? ModalRoute.of(context)?.settings.arguments as bool
        : false);
    final textController = useTextEditingController();
    final viewModel = useRef(SetGoalViewModel());
    useEffect(() {
      textController.text = viewModel.value.lucidManager.intentEntity.getDescription() ?? '';
      return null;
    }, []);
    return ViewModelBuilder.reactive(
      viewModelBuilder: () => viewModel.value,
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
                      'Set Goal',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lucid dreams are a lot more rewarding if you consciously aim to achieve an objective before you go to sleep.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 43),
                    Text(
                      LucidRealityCategoryExtension.fromTag(
                              viewModel.lucidManager.intentEntity.getCategoryID() ?? '')
                          .title,
                      style: Theme.of(context).textTheme.bodyMediumWithFontWeight700,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      textCapitalization: TextCapitalization.sentences,
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.bodySmall,
                      decoration: InputDecoration(
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        contentPadding: const EdgeInsets.all(16.00),
                        filled: true,
                        alignLabelWithHint: true,
                        label: const Text('What should my next product be?'),
                        fillColor: NextSenseColors.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none,
                        ),
                        labelStyle: Theme.of(context).textTheme.bodySmall,
                      ),
                      controller: textController,
                      keyboardType: TextInputType.multiline,
                      maxLines: 14,
                    ),
                    const Spacer(flex: 1),
                    RealityCheckBottomBar(
                      progressBarVisibility: !isStartForResult,
                      onPressed: () async {
                        await viewModel.lucidManager.updateDescription(textController.text.trim());
                        if (isStartForResult) {
                          viewModel.goBackWithResult(textController.text.trim());
                        } else {
                          viewModel.navigateToSetTimerScreen();
                        }
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
