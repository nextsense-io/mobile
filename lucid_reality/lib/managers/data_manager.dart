import 'package:logging/logging.dart';
import 'package:flutter_common/utils/android_logger.dart';
import 'package:lucid_reality/managers/session_manager.dart';

import '../di.dart';
import 'auth_manager.dart';
import 'event_types_manager.dart';

class DataManager {

  final CustomLogPrinter _logger = CustomLogPrinter('DataManager');

  final AuthManager _authManager = getIt<AuthManager>();
  final EventTypesManager _eventTypesManager = getIt<EventTypesManager>();
  final SessionManager _sessionManager = getIt<SessionManager>();

  bool get userLoaded => _userLoaded;
  bool get userDataLoaded => _userDataLoaded;

  bool _userLoaded = false;
  bool _userDataLoaded = false;

  Future<bool> loadUser() async {
    _userLoaded = await _authManager.ensureUserLoaded();
    if (!userLoaded) {
      _logger.log(Level.WARNING, 'Failed to load user. Fallback to signup');
      return false;
    }
    _userLoaded = true;
    _logger.log(Level.INFO, 'User loaded.');
    return true;
  }

  Future<bool> loadData() async {
    _logger.log(Level.INFO, 'Starting to load event types data.');
    bool loaded = await _eventTypesManager.loadEventTypes();
    if (!loaded) return false;
    await _sessionManager.loadCurrentSession();
    _userDataLoaded = true;
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