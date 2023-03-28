import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/planned_activity.dart';
import 'package:nextsense_trial_ui/domain/survey/runnable_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/survey.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';

class AdhocSurvey implements RunnableSurvey {
  final FirestoreManager _firestoreManager = getIt<FirestoreManager>();
  final AuthManager _authManager = getIt<AuthManager>();

  late String plannedSurveyId;
  late String? scheduledSurveyId;
  late Survey survey;
  late String studyId;

  ScheduleType get scheduleType => ScheduleType.adhoc;
  String? get resultId => getVa;

  AdhocSurvey(this.plannedSurveyId, this.survey, this.studyId);

  @override
  Future<bool> update({required SurveyState state, required String resultId}) async {
    DateTime now = DateTime.now();
    String adhocProtocolKey = "${survey.id}_at_${now.millisecondsSinceEpoch}";
    FirebaseEntity? surveyRecordEntity = await _firestoreManager.queryEntity([
      Table.users,
      Table.enrolled_studies,
      Table.adhoc_surveys
    ], [
      _authManager.username!,
      studyId,
      adhocProtocolKey
    ]);
    if (surveyRecordEntity == null) {
      return false;
    }
    final adhocSurvey = AdhocSurveyRecord(surveyRecordEntity);
    adhocSurvey.setPlannedSurveyId(survey.id);
    adhocSurvey.setResultId(resultId);
    return await adhocSurvey.save();
  }
}

enum AdhocSurveyRecordKey {
  planned_survey_id,
  result_id  // Survey record id
}

class AdhocSurveyRecord extends FirebaseEntity<AdhocSurveyRecordKey> {

  AdhocSurveyRecord(FirebaseEntity firebaseEntity) : super(firebaseEntity.getDocumentSnapshot());

  void setPlannedSurveyId(String plannedSurveyId) {
    setValue(AdhocSurveyRecordKey.planned_survey_id, plannedSurveyId);
  }

  void setResultId(String resultId) {
    setValue(AdhocSurveyRecordKey.result_id, resultId);
  }
}
