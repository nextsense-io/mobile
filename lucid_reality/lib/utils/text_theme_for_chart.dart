import 'package:community_charts_flutter/community_charts_flutter.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';

extension LucidRealityTextThemeForChart on TextStyleSpec {
  TextStyleSpec get caption {
    return TextStyleSpec(
      fontSize: 10,
      fontFamily: 'Montserrat',
      color: ColorUtil.fromDartColor(NextSenseColors.royalBlue),
    );
  }
}
