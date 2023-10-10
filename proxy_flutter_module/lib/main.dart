import 'package:flutter/services.dart';
import 'package:nextsense_consumer_ui/main.dart' as consumer_ui;
import 'package:nextsense_trial_ui/main.dart' as trial_ui;
import 'package:proxy_flutter_module/routes.dart';

void main() {
  umbrellaApp(routeTrialUi);
}

void umbrellaApp(String route) {
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
        SystemNavigator.pop(animated: true);
        break;
      }
  }
}