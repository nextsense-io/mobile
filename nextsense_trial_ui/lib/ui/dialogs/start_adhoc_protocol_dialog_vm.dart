import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/session/adhoc_session.dart';
import 'package:nextsense_trial_ui/domain/session/protocol.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/viewmodels/viewmodel.dart';

class StartAdhocProtocolDialogViewModel extends ViewModel {

  final StudyManager _studyManager = getIt<StudyManager>();

  List<AdhocSession> getAdhocProtocols() {
    List<ProtocolType> allowedProtocols = _studyManager.allowedAdhocProtocols;

    return allowedProtocols.map((protocolType) => AdhocSession(
        protocolType, _studyManager.currentStudyId!)).toList();
  }
}
