import 'dart:ui';

import '../ui/nextsense_colors.dart';

enum ResultType { coreSleep, deepSleep, remSleep, awakeSleep }

class BrainChecking {
  final String title;
  final int spendTime;
  final DateTime dateTime;
  final ResultType type;

  BrainChecking(this.title, this.spendTime, this.dateTime, this.type);
}

extension ColorBaseOnType on ResultType {
  Color getColor() {
    switch (this) {
      case ResultType.coreSleep:
        return NextSenseColors.coreSleep;
      case ResultType.deepSleep:
        return NextSenseColors.deepSleep;
      case ResultType.remSleep:
        return NextSenseColors.remSleep;
      case ResultType.awakeSleep:
        return NextSenseColors.awakeSleep;
    }
  }
}
