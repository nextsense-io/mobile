import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_common/utils/android_logger.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_consumer_ui/main.dart' as consumer_ui;
import 'package:nextsense_trial_ui/main.dart' as trial_ui;
import 'package:proxy_flutter_module/routes.dart';

void _initLogging() {
  Logger.root.level = Level.ALL;  // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _initLogging();
  getLogger("ProxyMain").log(Level.INFO, "Default route: ${window.defaultRouteName}");
  proxyApp(window.defaultRouteName ?? routeTrialUi);
}

void proxyApp(String route) {
  switch (route) {
    case routeTrialUi:
      {
        trial_ui.main();
        break;
      }
    case routeConsumerUi:
      {
        consumer_ui.main();
        break;
      }
    default:
      {
        getLogger("ProxyMain").log(Level.INFO, "Invalid route: $route");
        SystemNavigator.pop(animated: true);
        break;
      }
  }
}