enum Goal {
  moreLucid,
  startLucidDreaming,
  learnRelaxingDay,
  getBetterSleep,
  protectBrainHealth,
}

extension GoalExtension on Goal {
  String get tag {
    switch (this) {
      case Goal.moreLucid:
        return "be_more_lucid";
      case Goal.startLucidDreaming:
        return "start_lucid_dream";
      case Goal.learnRelaxingDay:
        return "lean_relaxing_day";
      case Goal.getBetterSleep:
        return "get_better_sleep";
      case Goal.protectBrainHealth:
        return "protect_brain_health";
    }
  }

  static Goal fromTag(String tag) {
    switch (tag) {
      case "be_more_lucid":
        return Goal.moreLucid;
      case "start_lucid_dream":
        return Goal.startLucidDreaming;
      case "lean_relaxing_day":
        return Goal.learnRelaxingDay;
      case "get_better_sleep":
        return Goal.getBetterSleep;
      case "protect_brain_health":
        return Goal.protectBrainHealth;
      default:
        return Goal.startLucidDreaming;
    }
  }
}

class Question {
  late final String _question;
  late final Goal _goal;
  late bool _isSelected;

  Question(this._question, this._goal, this._isSelected);

  String get question => _question;

  Goal get goal => _goal;

  bool get isSelected => _isSelected;

  set isSelected(bool value) {
    _isSelected = value;
  }

  set goal(Goal value) {
    _goal = value;
  }

  set question(String value) {
    _question = value;
  }
}
