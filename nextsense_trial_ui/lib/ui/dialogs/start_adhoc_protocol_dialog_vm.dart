import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/planned_session.dart';
import 'package:nextsense_trial_ui/domain/session/adhoc_session.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:flutter_common/viewmodels/viewmodel.dart';

class StartAdhocProtocolDialogViewModel extends ViewModel {

  final StudyManager _studyManager = getIt<StudyManager>();

  List<AdhocSession> getAdhocProtocols() {
    List<PlannedSession> allowedProtocols = _studyManager.allowedAdhocProtocols;

    return allowedProtocols.map((allowedProtocol) => AdhocSession(
        allowedProtocol.protocol!.type, allowedProtocol.id, _studyManager.currentStudyId!))
        .toList();
  }
}
