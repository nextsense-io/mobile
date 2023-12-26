import 'package:flutter/material.dart';

extension LucidRealityTextTheme on TextTheme {
  TextStyle? get labelLargeWithFontWeight600 {
    return labelLarge?.copyWith(fontWeight: FontWeight.w600);
  }

  TextStyle? get bodyMediumWithFontWeight300 {
    return bodyMedium?.copyWith(fontWeight: FontWeight.w300);
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

  TextStyle? get bodySmallWithFontWeight700 {
    return bodySmall?.copyWith(fontWeight: FontWeight.w700);
  }

  TextStyle? get bodySmallWithFontWeight700FontSize10 {
    return bodySmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 10);
  }

  TextStyle? get bodySmallWithFontSize10 {
    return bodySmall?.copyWith(fontSize: 10);
  }

  TextStyle? get bodyCaption {
    return bodySmall?.copyWith(fontSize: 12);
  }

  TextStyle? get titleMediumWithFontWeight500 {
    return titleMedium?.copyWith(fontWeight: FontWeight.w500);
  }
}
