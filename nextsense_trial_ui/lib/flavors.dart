import 'package:nextsense_trial_ui/domain/user.dart';

// Possible authentication methods.
enum AuthMethod {
  user_code,
  google_auth
}

abstract class Flavor {
  String getAppTitle();

  UserType getUserType();

  List<AuthMethod> getAuthMethods();
}

class SubjectFlavor extends Flavor {
  @override
  String getAppTitle() {
    return "NextSense Trial";
  }

  @override
  List<AuthMethod> getAuthMethods() {
    return [AuthMethod.user_code];
  }

  @override
  UserType getUserType() {
    return UserType.subject;
  }
}

class ResearcherFlavor extends Flavor {
  @override
  String getAppTitle() {
    return "NextSense Research";
  }

  @override
  List<AuthMethod> getAuthMethods() {
    return [AuthMethod.google_auth];
  }

  @override
  UserType getUserType() {
    return UserType.researcher;
  }
}

class FlavorFactory {
  static Flavor createFlavor(String? flavor) {
    UserType userType = UserType.values.firstWhere(
            (element) => element.name == flavor,
        orElse: () => UserType.unknown);
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