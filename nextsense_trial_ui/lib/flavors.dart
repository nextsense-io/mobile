import 'package:logging/logging.dart';
import 'package:flutter_common/managers/auth/auth_method.dart';
import 'package:flutter_common/utils/android_logger.dart';
import 'package:nextsense_trial_ui/domain/user.dart';

abstract class Flavor {
  String get appTitle;

  UserType get userType;

  List<AuthMethod> get authMethods;
}

class AnonymousSubjectFlavor extends Flavor {
  @override
  String get appTitle => "NextSense Trial";

  @override
  List<AuthMethod> get authMethods => [AuthMethod.user_code];

  @override
  UserType get userType => UserType.anonymous_subject;
}

class SubjectFlavor extends Flavor {
  @override
  String get appTitle => "NextSense Trial";

  @override
  List<AuthMethod> get authMethods => [AuthMethod.email_password];

  @override
  UserType get userType => UserType.subject;
}

class ResearcherFlavor extends Flavor {
  @override
  String get appTitle => "NextSense Research";

  @override
  List<AuthMethod> get authMethods => [AuthMethod.google_auth];

  UserType get userType => UserType.researcher;
}

class FlavorFactory {
  static Flavor createFlavor(String? flavor) {
    UserType userType = User.getUserTypeFromString(flavor);
    switch (userType) {
      case UserType.anonymous_subject:
        return AnonymousSubjectFlavor();
      case UserType.researcher:
        return ResearcherFlavor();
      case UserType.subject:
        return AnonymousSubjectFlavor();
      default:
        getLogger("Main").log(Level.INFO, "Unknown flavor: $flavor");
        throw("Unknown flavor: $flavor");
    }
  }
}