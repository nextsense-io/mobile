import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/study.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/viewmodels/viewmodel.dart';

class StudyIntroScreenViewModel extends ViewModel {

  final StudyManager _studyManager = getIt<StudyManager>();

  List<IntroPageContent> getIntroPageContents() {
    return _studyManager.introPageContents;
  }
}