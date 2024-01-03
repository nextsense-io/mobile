class LucidRealityCategory {
  late final LucidRealityCategoryEnum _category;

  LucidRealityCategory(this._category);

  LucidRealityCategoryEnum get category => _category;

  set category(LucidRealityCategoryEnum value) {
    _category = value;
  }
}

enum LucidRealityCategoryEnum {
  calmDown,
  boostCreativity,
  fun,
  personalInsight,
  outOfBodyExperience,
  problemSolving,
}

extension LucidRealityCategoryExtension on LucidRealityCategoryEnum {
  String get title {
    switch (this) {
      case LucidRealityCategoryEnum.calmDown:
        return 'CALM DOWN';
      case LucidRealityCategoryEnum.boostCreativity:
        return 'BOOST Creativity';
      case LucidRealityCategoryEnum.fun:
        return "FUN";
      case LucidRealityCategoryEnum.personalInsight:
        return "PERSONAL INSIGHT";
      case LucidRealityCategoryEnum.outOfBodyExperience:
        return "OUT OF BODY EXPERIENCE";
      case LucidRealityCategoryEnum.problemSolving:
        return "PROBLEM SOLVING";
    }
  }

  String get image {
    switch (this) {
      case LucidRealityCategoryEnum.calmDown:
        return 'c1_colm.png';
      case LucidRealityCategoryEnum.boostCreativity:
        return 'c2_creativity.png';
      case LucidRealityCategoryEnum.fun:
        return 'c3_fun.png';
      case LucidRealityCategoryEnum.personalInsight:
        return 'c4_personal_insight.png';
      case LucidRealityCategoryEnum.outOfBodyExperience:
        return 'c5_out_of_body.png';
      case LucidRealityCategoryEnum.problemSolving:
        return 'c6_problem_solving.png';
    }
  }

  String get tag {
    switch (this) {
      case LucidRealityCategoryEnum.calmDown:
        return 'c1';
      case LucidRealityCategoryEnum.boostCreativity:
        return 'c2';
      case LucidRealityCategoryEnum.fun:
        return 'c3';
      case LucidRealityCategoryEnum.personalInsight:
        return 'c4';
      case LucidRealityCategoryEnum.outOfBodyExperience:
        return 'c5';
      case LucidRealityCategoryEnum.problemSolving:
        return 'c6';
    }
  }

  static LucidRealityCategoryEnum fromTag(String tag) {
    switch (tag) {
      case "c1":
        return LucidRealityCategoryEnum.calmDown;
      case "c2":
        return LucidRealityCategoryEnum.boostCreativity;
      case "c3":
        return LucidRealityCategoryEnum.fun;
      case "c4":
        return LucidRealityCategoryEnum.personalInsight;
      case "c5":
        return LucidRealityCategoryEnum.outOfBodyExperience;
      case "c6":
        return LucidRealityCategoryEnum.problemSolving;
      default:
        return LucidRealityCategoryEnum.calmDown;
    }
  }
}
