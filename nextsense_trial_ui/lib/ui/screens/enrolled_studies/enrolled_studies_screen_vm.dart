import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/enrolled_study.dart';
import 'package:nextsense_trial_ui/domain/study.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/data_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/viewmodels/viewmodel.dart';

class EnrolledStudiesScreenViewModel extends ViewModel {
  final DataManager _dataManager = getIt<DataManager>();
  final StudyManager _studyManager = getIt<StudyManager>();
  final AuthManager _authManager = getIt<AuthManager>();

  List<EnrolledStudy>? enrolledStudies = [];
  Map<String, Study> _studies = {};

  String get currentStudyId => _studyManager.currentStudy!.getName();

  @override
  void init() async {
    super.init();
    enrolledStudies = await _studyManager.getEnrolledStudies(_authManager.user!.id);
    for (EnrolledStudy enrolledStudy in enrolledStudies!) {
      Study? study = await _studyManager.getStudy(enrolledStudy.id);
      if (study != null) {
        _studies[study.id] = study;
      }
    }

    setInitialised(true);
    notifyListeners();
  }

  Future<bool> changeCurrentStudy(EnrolledStudy enrolledStudy) async {
    setBusy(true);
    notifyListeners();
    bool studyChanged = await _dataManager.switchCurrentStudy(enrolledStudy);
    setBusy(false);
    notifyListeners();
    return studyChanged;
  }

  String getStudyName(String studyId) {
    return _studies[studyId]?.getName() ?? 'Not found';
  }
}