import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_common/utils/android_logger.dart';
import 'package:logging/logging.dart';
import 'package:lucid_reality/main.dart' as lucid_reality_ui;
import 'package:nextsense_consumer_ui/main.dart' as consumer_ui;
import 'package:nextsense_trial_ui/main.dart' as trial_ui;
import 'package:proxy_flutter_module/routes.dart';

void main() async {
  proxyApp(PlatformDispatcher.instance.defaultRouteName);
}

void proxyApp(String route) {
  print("routeName==>>$route");
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
    case routeLucidRealityUi:
      {
        lucid_reality_ui.main();
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
