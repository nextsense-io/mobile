import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_common/di.dart';
import 'package:flutter_common/utils/android_logger.dart';
import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:logging/logging.dart';
import 'package:lucid_reality/domain/lucid_reality_category.dart';
import 'package:lucid_reality/managers/auth_manager.dart';
import 'package:lucid_reality/managers/lucid_manager.dart';
import 'package:lucid_reality/preferences.dart';
import 'package:lucid_reality/ui/screens/dream_journal/dream_journal_screen.dart';
import 'package:lucid_reality/ui/screens/navigation.dart';
import 'package:lucid_reality/ui/screens/reality_check/lucid_reality_category_screen.dart';
import 'package:lucid_reality/ui/screens/reality_check/reality_check_bedtime_screen.dart';
import 'package:lucid_reality/ui/screens/reality_check/reality_check_time_screen.dart';
import 'package:lucid_reality/ui/screens/reality_check/reality_check_tone_category_screen.dart';
import 'package:lucid_reality/ui/screens/reality_check/set_goal_screen.dart';
import 'package:lucid_reality/ui/screens/rem_detect_onboarding/rem_detect_onboarding.dart';
import 'package:lucid_reality/utils/date_utils.dart';
import 'package:lucid_reality/utils/notification.dart';
import 'package:lucid_reality/utils/utils.dart';
import 'package:lucid_reality/utils/wear_os_connectivity.dart';

class LucidScreenViewModel extends ViewModel {
  final CustomLogPrinter _logger = CustomLogPrinter('LucidScreenViewModel');
  final Navigation _navigation = getIt<Navigation>();
  final AuthManager _authManager = getIt<AuthManager>();
  final LucidManager _lucidManager = getIt<LucidManager>();
  final LucidWearOsConnectivity _lucidWearOsConnectivity = getIt<LucidWearOsConnectivity>();

  final _preferences = getIt<Preferences>();
  LucidRealityCategoryEnum? _category;
  bool _isDoNotDisturbOverridden = false;

  bool get isDoNotDisturbOverridden => _isDoNotDisturbOverridden;

  @override
  void init() async {
    super.init();
    setBusy(true);
    final userLoaded = await _authManager.ensureUserLoaded();
    if (userLoaded) {
      await _lucidManager.fetchIntent();
      await _lucidManager.fetchRealityCheck();
      String? category = _lucidManager.intentEntity.getCategoryID();
      if (category != null) {
        _category = LucidRealityCategoryExtension.fromTag(category);
      }
      _isDoNotDisturbOverridden = await _checkIsDoNotDisturbOverridden();
    }
    notifyListeners();
    setBusy(false);
    _lucidManager.realityCheckingNotifier.addListener(
      () {
        notifyListeners();
      },
    );
    cancelledBedtimeNotificationIfWearAppConnected();
  }

  String getRealityCheckSound() {
    return _lucidManager.realityCheck
            .getRealityTest()
            ?.getTotemSound()
            ?.replaceAll(' ', '_')
            .toLowerCase() ??
        'air';
  }

  Future<bool> _checkIsDoNotDisturbOverridden() async {
    return await isDoNotDisturbOverriddenForChannel(
        notificationType: NotificationType.realityCheckingBedtimeNotification,
        sound: getRealityCheckSound());
  }

  void openChannelSettings() async {
    if (!await isDoNotDisturbOverriddenForChannel(
        notificationType: NotificationType.realityCheckingBedtimeNotification,
        sound: getRealityCheckSound())) {
      await requestDoNotDisturbOverride(
          notificationType: NotificationType.realityCheckingBedtimeNotification,
          sound: getRealityCheckSound());
    }
    _isDoNotDisturbOverridden = await _checkIsDoNotDisturbOverridden();
    notifyListeners();
  }

  void navigateToCategoryScreen() {
    _navigation.navigateTo(LucidRealityCategoryScreen.id);
  }

  void navigateToCategoryScreenForResult() async {
    final resultCategory =
        await _navigation.navigateTo(LucidRealityCategoryScreen.id, arguments: true);
    if (resultCategory is LucidRealityCategory) {
      _category = resultCategory.category;
      notifyListeners();
    }
  }

  bool isRealitySettingsCompleted() {
    return _lucidManager.realityCheck.getBedTime() != null &&
        _lucidManager.realityCheck.getWakeTime() != null;
  }

  void navigateToDreamJournalScreen() {
    _navigation.navigateTo(DreamJournalScreen.id);
  }

  String realityCheckTitle() {
    return _category?.title ?? '';
  }

  String realityCheckImage() {
    return _category?.image ?? 'c1_colm.png';
  }

  String realityCheckDescription() => _lucidManager.intentEntity.getDescription() ?? '';

  String realityCheckingStartTime() =>
      _lucidManager.realityCheck.getStartTime()?.toDate().getTime() ?? '';

  String realityCheckingEndTime() =>
      _lucidManager.realityCheck.getEndTime()?.toDate().getTime() ?? '';

  String realityCheckingBedTime() =>
      _lucidManager.realityCheck.getBedTime()?.toDate().getTime() ?? '';

  String realityCheckingWakeUpTime() =>
      _lucidManager.realityCheck.getWakeTime()?.toDate().getTime() ?? '';

  String realityCheckActionName() => _lucidManager.realityCheck.getRealityTest()?.getName() ?? '';

  int getNumberOfReminders() => _lucidManager.realityCheck.getNumberOfReminders();

  bool get isREMDetectionOnboardingCompleted =>
      _preferences.getBool(PreferenceKey.isREMDetectionOnboardingCompleted);

  void navigateToSetGoalScreenForResult() async {
    final result = await _navigation.navigateTo(SetGoalScreen.id, arguments: true);
    if (result is String) {
      notifyListeners();
    }
  }

  void navigateToRealityCheckTimeScreenForResult() async {
    final result = await _navigation.navigateTo(RealityCheckTimeScreen.id, arguments: true);
    if (result is String) {
      notifyListeners();
    }
  }

  void navigateToRealityCheckBedtimeScreenForResult() async {
    final result = await _navigation.navigateTo(RealityCheckBedtimeScreen.id, arguments: true);
    if (result is String) {
      notifyListeners();
    }
  }

  void navigateToToneCategoryScreenForResult() async {
    final result = await _navigation.navigateTo(RealityCheckToneCategoryScreen.id, arguments: true);
    if (result is String) {
      notifyListeners();
    }
  }

  void navigateToREMDetectionOnboardingScreen() {
    _navigation.navigateTo(REMDetectionOnboarding.id);
    _preferences.setBool(PreferenceKey.isREMDetectionOnboardingCompleted, true);
    notifyListeners();
  }

  void cancelledBedtimeNotificationIfWearAppConnected() async {
    final isCompanionAppInstalled = await _lucidWearOsConnectivity.isCompanionAppInstalled();
    if (isCompanionAppInstalled) {
      await AwesomeNotifications().cancelSchedulesByChannelKey(
          NotificationType.realityCheckingBedtimeNotification.notificationChannelKey);
      _logger.log(Level.WARNING, "Since the companion watch app has been installed, there's no need to schedule a local notification, so we return.");
    }
  }
}
