class LucidRealityCategory {
  late final LucidRealityCategoryEnum _category;

  LucidRealityCategory(this._category);

  LucidRealityCategoryEnum get category => _category;

  set category(LucidRealityCategoryEnum value) {
    _category = value;
  }
}

enum LucidRealityCategoryEnum {
  c1,
  c2,
  c3,
  c4,
  c5,
  c6,
}

extension LucidRealityCategoryExtension on LucidRealityCategoryEnum {
  String get title {
    switch (this) {
      case LucidRealityCategoryEnum.c1:
        return 'CALM DOWN';
      case LucidRealityCategoryEnum.c2:
        return 'BOOST Creativity';
      case LucidRealityCategoryEnum.c3:
        return "FUN";
      case LucidRealityCategoryEnum.c4:
        return "PERSONAL INSIGHT";
      case LucidRealityCategoryEnum.c5:
        return "OUT OF BODY EXPERIENCE";
      case LucidRealityCategoryEnum.c6:
        return "PROBLEM SOLVING";
    }
  }

  String get image {
    switch (this) {
      case LucidRealityCategoryEnum.c1:
        return 'c1_colm.png';
      case LucidRealityCategoryEnum.c2:
        return 'c2_creativity.png';
      case LucidRealityCategoryEnum.c3:
        return 'c3_fun.png';
      case LucidRealityCategoryEnum.c4:
        return 'c4_personal_insight.png';
      case LucidRealityCategoryEnum.c5:
        return 'c5_out_of_body.png';
      case LucidRealityCategoryEnum.c6:
        return 'c6_problem_solving.png';
    }
  }

  static LucidRealityCategoryEnum fromTag(String tag) {
    switch (tag) {
      case "c1":
        return LucidRealityCategoryEnum.c1;
      case "c2":
        return LucidRealityCategoryEnum.c2;
      case "c3":
        return LucidRealityCategoryEnum.c3;
      case "c4":
        return LucidRealityCategoryEnum.c4;
      case "c5":
        return LucidRealityCategoryEnum.c5;
      case "c6":
        return LucidRealityCategoryEnum.c6;
      default:
        return LucidRealityCategoryEnum.c1;
    }
  }
}
