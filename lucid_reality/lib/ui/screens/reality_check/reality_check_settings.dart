import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucid_reality/ui/components/app_card.dart';
import 'package:lucid_reality/ui/components/app_text_button.dart';
import 'package:lucid_reality/ui/dialogs/app_dialogs.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
import 'package:lucid_reality/ui/screens/lucid/lucid_screen_vm.dart';
import 'package:lucid_reality/utils/notification.dart';
import 'package:lucid_reality/utils/text_theme.dart';
import 'package:lucid_reality/utils/utils.dart';

enum RealitySettingsViewType { home, lucid }

class RealityCheckSettings extends HookWidget {
  final LucidScreenViewModel viewModel;
  final RealitySettingsViewType viewType;
  final Function()? onSetupSettings;

  const RealityCheckSettings(
    this.viewModel, {
    super.key,
    this.viewType = RealitySettingsViewType.lucid,
    this.onSetupSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isNotificationEnabled = useState(false);
    final appLifecycleState = useAppLifecycleState();
    final batteryOptimizationState = useState(BatteryOptimizationState.unknown);
    final onContinue = () async {
      final isNotificationAllow = await notificationPermission(context);
      if (isNotificationAllow) {
        /// Checking battery optimization is enabled or disabled. If it is enabled, we will ask the user to disable it, and then immediately return 'isInProgress' for further checking. Otherwise, return the status 'disable'.
        batteryOptimizationState.value = await context.isBatteryOptimizationDisabled();
        if (batteryOptimizationState.value == BatteryOptimizationState.isDisabled) {
          isNotificationEnabled.value = true;
        }
      }
    };
    //Check for notification permission, user or system may revoked it.
    useEffect(() {
      if (appLifecycleState == AppLifecycleState.resumed) {
        if (batteryOptimizationState.value == BatteryOptimizationState.isInProgress) {
          batteryOptimizationState.value = BatteryOptimizationState.isCompleted;
          onContinue.call();
        }
        Future.sync(
          () async {
            isNotificationEnabled.value = await isNotificationAllowed();
          },
        );
      }
      return null;
    }, [appLifecycleState]);
    if (!viewModel.isRealitySettingsCompleted()) {
      return InkWell(
        onTap: onSetupSettings,
        child: AppCard(
          padding: EdgeInsets.zero,
          Stack(
            children: [
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Image.asset(imageBasePath.plus('lucid_icon.png')),
              ),
              Container(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 80, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Lucid Dreaming',
                        style: Theme.of(context).textTheme.bodyMediumWithFontWeight600,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Set a goal and reality check alerts to help you get started with lucid dreaming.',
                        style: Theme.of(context).textTheme.bodyCaption,
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      );
    } else {
      if (isNotificationEnabled.value == false) {
        return Container(
          width: double.maxFinite,
          child: AppCard(
            Column(
              children: [
                Text("Our app would like to send you notifications"),
                SizedBox(height: 16),
                AppTextButton(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  backgroundImage: 'btn_authorize.svg',
                  onPressed: onContinue,
                  text: "Allow Notifications",
                )
              ],
            ),
          ),
        );
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (viewType == RealitySettingsViewType.lucid) ...[
            Text(
              'CURRENT SETTINGS',
              style: Theme.of(context).textTheme.bodySmallWithFontWeight700FontSize12,
            ),
            const SizedBox(height: 5),
          ],
          AppCard(
            padding: EdgeInsets.only(left: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          viewModel.navigateToCategoryScreenForResult();
                        },
                        child: Text(
                          viewModel.realityCheckTitle(),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmallWithFontWeight700
                              ?.copyWith(color: NextSenseColors.skyBlue),
                        ),
                      ),
                      SizedBox(height: 8),
                      InkWell(
                        onTap: () {
                          viewModel.navigateToSetGoalScreenForResult();
                        },
                        child: Text(
                          viewModel.realityCheckDescription(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 81,
                  child: Image.asset(imageBasePath.plus(viewModel.realityCheckImage())),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 1,
                child: RealityCheckSettingsWidget(
                  title: 'Reality check time',
                  description:
                      '${viewModel.getNumberOfReminders()} times\n${viewModel.realityCheckingStartTime()}-${viewModel.realityCheckingEndTime()}',
                  titleColor: NextSenseColors.coral,
                  onPressed: () {
                    viewModel.navigateToRealityCheckTimeScreenForResult();
                  },
                ),
              ),
              SizedBox(width: 4),
              Expanded(
                flex: 1,
                child: RealityCheckSettingsWidget(
                  title: 'Reality check Action',
                  description: '${viewModel.realityCheckActionName()}',
                  titleColor: NextSenseColors.royalPurple,
                  onPressed: () {
                    viewModel.navigateToToneCategoryScreenForResult();
                  },
                ),
              ),
              SizedBox(width: 4),
              Expanded(
                flex: 1,
                child: RealityCheckSettingsWidget(
                  title: 'Bedtime',
                  description:
                      '${viewModel.getNumberOfReminders()} times from\n${viewModel.realityCheckingBedTime()}-${viewModel.realityCheckingWakeUpTime()}',
                  titleColor: NextSenseColors.royalBlue,
                  onPressed: () {
                    viewModel.navigateToRealityCheckBedtimeScreenForResult();
                  },
                ),
              ),
            ],
          ),
        ],
      );
    }
  }
}

class RealityCheckSettingsWidget extends StatelessWidget {
  final String title;
  final String description;
  final Color titleColor;
  final VoidCallback? onPressed;

  const RealityCheckSettingsWidget(
      {super.key,
      required this.title,
      required this.description,
      required this.titleColor,
      this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: AppCard(
        SizedBox(
          height: 64,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .bodySmallWithFontWeight700FontSize10
                    ?.copyWith(color: titleColor),
              ),
              const SizedBox(height: 16),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  maxLines: 2,
                  description,
                  style: Theme.of(context).textTheme.bodySmallWithFontSize10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
