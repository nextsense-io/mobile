import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucid_reality/ui/components/app_body.dart';
import 'package:lucid_reality/ui/components/app_card.dart';
import 'package:lucid_reality/ui/components/app_close_button.dart';
import 'package:lucid_reality/ui/components/svg_button.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
import 'package:lucid_reality/ui/screens/dream_journal/dream_confirmation_vm.dart';
import 'package:stacked/stacked.dart';

class DreamConfirmationScreen extends HookWidget {
  static const String id = 'dream_confirmation_screen';

  const DreamConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder.reactive(
      viewModelBuilder: () => DreamConfirmationViewModel(),
      onViewModelReady: (viewModel) => viewModel.init(),
      builder: (context, viewModel, child) {
        return SafeArea(
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: NextSenseColors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              actions: [
                AppCloseButton(
                  onPressed: () {
                    viewModel.goBack();
                  },
                )
              ],
            ),
            body: AppBody(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Did you see the dream you wanted to see?',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 28),
                    Flexible(
                      flex: 9,
                      child: AppCard(
                        Container(
                          width: double.maxFinite,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              SvgButton(
                                imageName: 'ic_full_circle.svg',
                                onPressed: () {
                                  viewModel.navigateToDreamYourRecordScreen(5);
                                },
                              ),
                              SvgButton(
                                imageName: 'ic_third_fourth_circle.svg',
                                onPressed: () {
                                  viewModel.navigateToDreamYourRecordScreen(4);
                                },
                              ),
                              SvgButton(
                                imageName: 'ic_half_circle.svg',
                                onPressed: () {
                                  viewModel.navigateToDreamYourRecordScreen(3);
                                },
                              ),
                              SvgButton(
                                imageName: 'ic_quarter_circle.svg',
                                onPressed: () {
                                  viewModel.navigateToDreamYourRecordScreen(2);
                                },
                              ),
                              SvgButton(
                                imageName: 'ic_empty_circle.svg',
                                onPressed: () {
                                  viewModel.navigateToDreamYourRecordScreen(1);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Spacer(flex: 1),
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
