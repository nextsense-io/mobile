import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucid_reality/ui/components/oval_button.dart';
import 'package:lucid_reality/ui/screens/sleep/no_sleep_data_screen_vm.dart';
import 'package:lucid_reality/utils/utils.dart';
import 'package:stacked/stacked.dart';

class NoSleepDataScreen extends HookWidget {
  static const String id = 'no_sleep_data_screen';

  const NoSleepDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder.reactive(
        viewModelBuilder: () => NoSleepDataViewModel(),
    onViewModelReady: (viewModel) => viewModel.init(),
    builder: (context, viewModel, child) {
      Widget body = SingleChildScrollView(child: Column(children: [
        Text("You need to Health Connect enable an application where your sleep is tracked to make "
            "it available to Lucid Reality. These 3 are the most common, but any applications that"
            " can sync it's sleep data with Health Connect will work.",
          style: Theme.of(context).textTheme.labelLarge, textAlign: TextAlign.justify),
        SizedBox(height: 16),
        Text("Samsung Health", style: Theme.of(context).textTheme.bodyLarge),
        SizedBox(height: 16),
        Text("Open Settings from the top right menu", style: Theme.of(context).textTheme.bodyLarge),
        Text("Tap \"Health Connect\"", style: Theme.of(context).textTheme.bodyLarge),
        Text("Allow the permissions", style: Theme.of(context).textTheme.bodyLarge),
        SizedBox(height: 16),
        Image.asset(imageBasePath.plus("samsung_health_settings.png")),
        SizedBox(height: 16),
        OvalButton(
            onTap: () {
              viewModel.openSamsungHealthApp();
            },
            text: "Launch Samsung Health", showBackground: true),
        SizedBox(height: 16),
        Text("Fitbit", style: Theme.of(context).textTheme.bodyLarge),
        SizedBox(height: 16),
        Text("Tap the user icon at the top right of the screen",
            style: Theme.of(context).textTheme.bodyLarge),
        Text("Select \"fitbit settings\"", style: Theme.of(context).textTheme.bodyLarge),
        Text("Select \"fitbit settings\"", style: Theme.of(context).textTheme.bodyLarge),
        Text("Press \"Health Connect\"", style: Theme.of(context).textTheme.bodyLarge),
        Text("Switch on \"Sync with Health Connect\"",
            style: Theme.of(context).textTheme.bodyLarge),
        SizedBox(height: 16),
        Image.asset(imageBasePath.plus("fitbit_settings.png")),
        SizedBox(height: 32),
        Image.asset(imageBasePath.plus("fitbit_health_connect.png")),
        SizedBox(height: 16),
        OvalButton(
            onTap: () {
              viewModel.openFitbitApp();
            },
            text: "Launch Fitbit", showBackground: true),
        SizedBox(height: 16),
        Text("google Fit", style: Theme.of(context).textTheme.bodyLarge),
        SizedBox(height: 16),
        Text("Go to the profile tab using the bottom menu",
            style: Theme.of(context).textTheme.bodyLarge),
        SizedBox(height: 16),
        Text("Open the settings using the cog icon in the top right",
            style: Theme.of(context).textTheme.bodyLarge),
        SizedBox(height: 16),
        Text("Switch on the \"Sync Fit with Health Connect\" option and accept the permissions",
            style: Theme.of(context).textTheme.bodyLarge),
        SizedBox(height: 16),
        Image.asset(imageBasePath.plus("google_fit_settings.png")),
        SizedBox(height: 16),
        OvalButton(
            onTap: () {
              viewModel.openGoogleFitApp();
            },
            text: "Launch Fit", showBackground: true),
      ]));
      return SafeArea(
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  imageBasePath.plus("app_background.png"),
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(child: body),
            ),
          ),
        ),
      );
    });
  }
}