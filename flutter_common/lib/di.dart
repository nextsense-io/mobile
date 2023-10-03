import 'package:flutter_common/managers/nextsense_api.dart';
import 'package:flutter_common/managers/permissions_manager.dart';
import 'package:get_it/get_it.dart';

GetIt getIt = GetIt.instance;

Future<void> initDependencies(String configBaseUrl) async {
  // The order here matters as some of these components might use a component
  // that was initialised before.
  getIt.registerSingleton<PermissionsManager>(PermissionsManager());
  getIt.registerSingleton<NextsenseApi>(NextsenseApi(configBaseUrl));
}
