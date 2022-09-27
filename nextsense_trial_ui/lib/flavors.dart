import 'package:nextsense_trial_ui/domain/user.dart';

// Possible authentication methods.
enum AuthMethod {
  email_password,
  user_code,
  google_auth
}

abstract class Flavor {
  String get appTitle;

  UserType get userType;

  List<AuthMethod> get authMethods;
}

class SubjectFlavor extends Flavor {
  @override
  String get appTitle => "NextSense Trial";

  @override
  List<AuthMethod> get authMethods => [AuthMethod.user_code];

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
      case UserType.researcher:
        return ResearcherFlavor();
      case UserType.subject:
        return SubjectFlavor();
      default:
        throw("Unknown flavor: $flavor");
    }
  }
}