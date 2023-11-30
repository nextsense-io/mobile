import 'package:flutter/material.dart';

extension LucidRealityTextTheme on TextTheme {
  TextStyle? get labelLargeWithFontWeight600 {
    return labelLarge?.copyWith(fontWeight: FontWeight.w600);
  }

  TextStyle? get bodyMediumWithFontWeight600 {
    return bodyMedium?.copyWith(fontWeight: FontWeight.w600);
  }

  TextStyle? get bodyMediumWithFontWeight700 {
    return bodyMedium?.copyWith(fontWeight: FontWeight.w700);
  }

  TextStyle? get bodySmallWithFontWeight600FontSize12 {
    return bodySmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 12);
  }

  TextStyle? get bodySmallWithFontWeight700FontSize12 {
    return bodySmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 12);
  }

  TextStyle? get bodySmallWithFontWeight600 {
    return bodySmall?.copyWith(fontWeight: FontWeight.w600);
  }

  TextStyle? get bodyCaption {
    return bodySmall?.copyWith(fontSize: 12);
  }
}
