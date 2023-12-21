class LucidRealityCategory {
  late final LucidRealityCategoryEnum _category;
  late final String _image;

  LucidRealityCategory(this._category, this._image);

  LucidRealityCategoryEnum get category => _category;


  String get image => _image;

  set imagePath(String value) {
    _image = value;
  }

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
