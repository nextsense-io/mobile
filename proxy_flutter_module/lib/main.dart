import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_common/utils/android_logger.dart';
import 'package:logging/logging.dart';
import 'package:nextsense_consumer_ui/main.dart' as consumer_ui;
import 'package:nextsense_trial_ui/main.dart' as trial_ui;
import 'package:proxy_flutter_module/routes.dart';
import 'package:receive_intent/receive_intent.dart' as intent;

void _initLogging() {
  Logger.root.level = Level.ALL;  // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
}

Future<intent.Intent?> _getInitialIntent() async {
  // Platform messages may fail, so we use a try/catch PlatformException.
  try {
    final receivedIntent = await intent.ReceiveIntent.getInitialIntent();
    getLogger("ProxyMain").log(Level.INFO, "Initial Intent: $receivedIntent");
    // Validate receivedIntent and warn the user, if it is not correct,
    // but keep in mind it could be `null` or "empty"(`receivedIntent.isNull`).
    if (receivedIntent == null || (receivedIntent.extra == null &&
        receivedIntent.data == null)) {
      getLogger("ProxyMain").log(Level.INFO, "Initial intent does not have data or extras, ignoring.");
      return null;
    }
    return receivedIntent;
  } on PlatformException {
    getLogger("ProxyMain").log(Level.INFO, "Error getting initial intent.");
  }
  return null;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _initLogging();
  intent.Intent? initialIntent = await _getInitialIntent();
  String? route = initialIntent != null && initialIntent.extra != null &&
      initialIntent.extra!.isNotEmpty ? initialIntent.extra!['route'] : null;
  umbrellaApp(route ?? routeTrialUi);
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
        getLogger("ProxyMain").log(Level.INFO, "Invalid route: $route");
        SystemNavigator.pop(animated: true);
        break;
      }
  }
}