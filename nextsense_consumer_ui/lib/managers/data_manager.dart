import 'package:logging/logging.dart';
import 'package:flutter_common/utils/android_logger.dart';
import 'package:nextsense_consumer_ui/di.dart';
import 'package:nextsense_consumer_ui/managers/auth_manager.dart';
import 'package:nextsense_consumer_ui/managers/event_types_manager.dart';
import 'package:nextsense_consumer_ui/managers/session_manager.dart';

class DataManager {

  final CustomLogPrinter _logger = CustomLogPrinter('DataManager');

  final AuthManager _authManager = getIt<AuthManager>();
  final EventTypesManager _eventTypesManager = getIt<EventTypesManager>();
  final SessionManager _sessionManager = getIt<SessionManager>();

  bool userLoaded = false;
  bool userStudyDataLoaded = false;

  Future<bool> loadUser() async {
    userLoaded = await _authManager.ensureUserLoaded();
    if (!userLoaded) {
      _logger.log(Level.WARNING, 'Failed to load user. Fallback to signup');
      return false;
    }
    userLoaded = true;
    _logger.log(Level.INFO, 'User loaded.');
    return true;
  }

  Future<bool> loadData() async {
    _logger.log(Level.INFO, 'Starting to load event types data.');
    bool loaded = await _eventTypesManager.loadEventTypes();
    if (!loaded) return false;
    await _sessionManager.loadCurrentSession();
    return true;
  }

  Future<bool> loadUserData() async {
    bool loaded = await loadUser();
    if (userLoaded) {
      loaded = await loadData();
    }
    return loaded;
  }
}