import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/enrolled_study.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/data_manager.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/viewmodels/viewmodel.dart';

class EnrolledStudiesScreenViewModel extends ViewModel {
  final DataManager _dataManager = getIt<DataManager>();
  final StudyManager _studyManager = getIt<StudyManager>();
  final AuthManager _authManager = getIt<AuthManager>();

  List<EnrolledStudy>? enrolledStudies = [];

  String get currentStudyId => _studyManager.currentStudyId!;

  @override
  void init() async {
    enrolledStudies = await _studyManager.getEnrolledStudies(_authManager.user!.id);
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
}