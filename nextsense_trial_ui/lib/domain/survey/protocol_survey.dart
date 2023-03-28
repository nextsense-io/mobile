import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/planned_activity.dart';
import 'package:nextsense_trial_ui/domain/survey/adhoc_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/runnable_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/survey.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';

class ProtocolSurvey implements RunnableSurvey {
  final FirestoreManager _firestoreManager = getIt<FirestoreManager>();

  late Survey survey;
  late String sessionId;

  ScheduleType get scheduleType => ScheduleType.conditional;

  ProtocolSurvey(this.survey, this.sessionId);

  @override
  Future<bool> update({required SurveyState state, Map<String, dynamic>? data,
    bool persist = true}) async {
    // Create new record only when we submit some data.
    if (data != null) {
      return await save(data);
    }
    return true;
  }

  Future<bool> save(Map<String, dynamic> data) async {
    DateTime now = DateTime.now();
    String protocolSurveyKey = "${survey.id}_at_${now.millisecondsSinceEpoch}";
    FirebaseEntity? surveyRecordEntity = await _firestoreManager.queryEntity([
      Table.sessions,
      Table.protocol_surveys
    ], [
      sessionId,
      protocolSurveyKey
    ]);
    if (surveyRecordEntity == null) {
      return false;
    }
    final record = AdhocSurveyRecord(surveyRecordEntity);
    record.setSurvey(survey.id);
    record.setTimestamp(now);
    record.setData(data);
    return await record.save();
  }
}
