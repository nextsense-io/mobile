import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/survey/runnable_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/survey.dart';
import 'package:nextsense_trial_ui/managers/auth/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';

class AdhocSurvey implements RunnableSurvey {
  final FirestoreManager _firestoreManager = getIt<FirestoreManager>();
  final AuthManager _authManager = getIt<AuthManager>();

  late Survey survey;
  late String studyId;

  RunnableSurveyType get type => RunnableSurveyType.adhoc;

  AdhocSurvey(this.survey, this.studyId);

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
    String adhocProtocolKey = "${survey.id}_at_${now.millisecondsSinceEpoch}";
    FirebaseEntity? surveyRecordEntity = await _firestoreManager.queryEntity([
      Table.users,
      Table.enrolled_studies,
      Table.adhoc_surveys
    ], [
      _authManager.userCode!,
      studyId,
      adhocProtocolKey
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

enum AdhocSurveyRecordKey {
  survey,
  timestamp,
  data
}

class AdhocSurveyRecord extends FirebaseEntity<AdhocSurveyRecordKey> {

  AdhocSurveyRecord(FirebaseEntity firebaseEntity) :
        super(firebaseEntity.getDocumentSnapshot());

  void setTimestamp(DateTime timestamp) {
    setValue(AdhocSurveyRecordKey.timestamp, timestamp.toIso8601String());
  }

  void setSurvey(String surveyId) {
    setValue(AdhocSurveyRecordKey.survey, surveyId);
  }

  void setData(Map<String, dynamic> data) {
    setValue(AdhocSurveyRecordKey.data, data);
  }
}
