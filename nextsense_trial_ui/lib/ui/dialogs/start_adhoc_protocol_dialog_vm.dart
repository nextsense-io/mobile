import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/protocol/adhoc_protocol.dart';
import 'package:nextsense_trial_ui/domain/protocol/protocol.dart';
import 'package:nextsense_trial_ui/managers/study_manager.dart';
import 'package:nextsense_trial_ui/viewmodels/viewmodel.dart';

class StartAdhocProtocolDialogViewModel extends ViewModel {

  final StudyManager _studyManager = getIt<StudyManager>();

  List<AdhocProtocol> getAdhocProtocols() {
    List<ProtocolType> allowedProtocols = _studyManager.allowedAdhocProtocols;

    return allowedProtocols.map((protocolType) => AdhocProtocol(
        protocolType, _studyManager.currentStudyId!)).toList();
  }
}
