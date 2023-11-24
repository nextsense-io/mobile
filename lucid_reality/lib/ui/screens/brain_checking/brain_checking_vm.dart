import 'package:flutter_common/viewmodels/viewmodel.dart';
import 'package:lucid_reality/domain/brain_checking.dart';

class BrainCheckingViewModule extends ViewModel {
  List brainCheckingResult = <BrainChecking>[];

  @override
  void init() {
    super.init();
    brainCheckingResult.add(
      BrainChecking(
        'Highly Alert',
        0000,
        DateTime(
          2023,
          10,
          8,
          9,
          5,
        ),
        ResultType.awakeSleep,
      ),
    );
    brainCheckingResult.add(
      BrainChecking(
        'Sleepy',
        0000,
        DateTime(
          2023,
          10,
          7,
          20,
          35,
        ),
        ResultType.coreSleep,
      ),
    );
  }
}
