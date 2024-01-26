import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_common/ui/components/tab_row.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucid_reality/ui/components/app_card.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
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
      Widget body = SingleChildScrollView(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Enable Health Connect", style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.left),
        SizedBox(height: 16),
        AppCard(Text("To see your sleep data, you must enable Health Connect in any applications currently "
            "tracking your sleep (e.g., FitBit, Samsung Health, Google Fit).\n\nSee below for "
            "instructions on the two most common scenarios, but any app that can sync its data "
            "with Health Connect will have similar options.",
          style: Theme.of(context).textTheme.bodyMedium)),
        SizedBox(height: 16),
        AppCard(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Google Fit", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
              color: NextSenseColors.royalBlue)),
          SizedBox(height: 16),
          TabRow(tabHeader: Text("1.", style: Theme.of(context).textTheme.bodyMedium),
              content: Text("Go to the profile tab using the bottom menu",
              style: Theme.of(context).textTheme.bodyMedium)),
          TabRow(tabHeader: Text("2.", style: Theme.of(context).textTheme.bodyMedium),
              content: Text("Open the settings using the cog icon in the top "
              "right",
              style: Theme.of(context).textTheme.bodyMedium)),
          TabRow(tabHeader: Text("3.", style: Theme.of(context).textTheme.bodyMedium),
              content: Text("Switch on the \"Sync Fit with Health Connect\" "
              "option and accept the permissions",
              style: Theme.of(context).textTheme.bodyMedium)),
        ])),
        AppCard(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Samsung Health", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
              color: NextSenseColors.skyBlue)),
          SizedBox(height: 16),
          TabRow(tabHeader: Text("1.", style: Theme.of(context).textTheme.bodyMedium),
              content: Text("Open Settings from the top right menu",
              style: Theme.of(context).textTheme.bodyMedium)),
          TabRow(tabHeader: Text("2.", style: Theme.of(context).textTheme.bodyMedium),
              content: Text("Tap \"Health Connect\"",
              style: Theme.of(context).textTheme.bodyMedium)),
          TabRow(tabHeader: Text("3.", style: Theme.of(context).textTheme.bodyMedium),
              content: Text("Allow the permissions",
              style: Theme.of(context).textTheme.bodyMedium)),
        ])),
        SizedBox(height: 8),
        AppCard(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Fitbit", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
              color: NextSenseColors.coral)),
          SizedBox(height: 16),
          TabRow(tabHeader: Text("1.", style: Theme.of(context).textTheme.bodyMedium),
              content: Text("Open FitBit Settings",
              style: Theme.of(context).textTheme.bodyMedium)),
          TabRow(tabHeader:Text("2.", style: Theme.of(context).textTheme.bodyMedium),
              content: Text("Select \"Health Connect\"",
              style: Theme.of(context).textTheme.bodyMedium)),
          TabRow(tabHeader: Text("3.", style: Theme.of(context).textTheme.bodyMedium),
              content: Text("Allow \"Sync with Health Connect\"",
              style: Theme.of(context).textTheme.bodyMedium)),
        ])),

        // Text("Samsung Health", style: Theme.of(context).textTheme.bodyLarge),
        // SizedBox(height: 16),
        // Text("Open Settings from the top right menu", style: Theme.of(context).textTheme.bodyLarge),
        // Text("Tap \"Health Connect\"", style: Theme.of(context).textTheme.bodyLarge),
        // Text("Allow the permissions", style: Theme.of(context).textTheme.bodyLarge),
        // SizedBox(height: 16),
        // Image.asset(imageBasePath.plus("samsung_health_settings.png")),
        // SizedBox(height: 16),
        // OvalButton(
        //     onTap: () {
        //       viewModel.openSamsungHealthApp();
        //     },
        //     text: "Launch Samsung Health", showBackground: true),
        // SizedBox(height: 16),
        // Text("Fitbit", style: Theme.of(context).textTheme.bodyLarge),
        // SizedBox(height: 16),
        // Text("Tap the user icon at the top right of the screen",
        //     style: Theme.of(context).textTheme.bodyLarge),
        // Text("Select \"fitbit settings\"", style: Theme.of(context).textTheme.bodyLarge),
        // Text("Select \"fitbit settings\"", style: Theme.of(context).textTheme.bodyLarge),
        // Text("Press \"Health Connect\"", style: Theme.of(context).textTheme.bodyLarge),
        // Text("Switch on \"Sync with Health Connect\"",
        //     style: Theme.of(context).textTheme.bodyLarge),
        // SizedBox(height: 16),
        // Image.asset(imageBasePath.plus("fitbit_settings.png")),
        // SizedBox(height: 32),
        // Image.asset(imageBasePath.plus("fitbit_health_connect.png")),
        // SizedBox(height: 16),
        // OvalButton(
        //     onTap: () {
        //       viewModel.openFitbitApp();
        //     },
        //     text: "Launch Fitbit", showBackground: true),
        // SizedBox(height: 16),
        // Text("Google Fit", style: Theme.of(context).textTheme.bodyLarge),
        // SizedBox(height: 16),
        // Text("Go to the profile tab using the bottom menu",
        //     style: Theme.of(context).textTheme.bodyLarge),
        // SizedBox(height: 16),
        // Text("Open the settings using the cog icon in the top right",
        //     style: Theme.of(context).textTheme.bodyLarge),
        // SizedBox(height: 16),
        // Text("Switch on the \"Sync Fit with Health Connect\" option and accept the permissions",
        //     style: Theme.of(context).textTheme.bodyLarge),
        // SizedBox(height: 16),
        // Image.asset(imageBasePath.plus("google_fit_settings.png")),
        // SizedBox(height: 16),
        // OvalButton(
        //     onTap: () {
        //       viewModel.openGoogleFitApp();
        //     },
        //     text: "Launch Fit", showBackground: true),
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