import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/survey/runnable_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/survey.dart';
import 'package:nextsense_trial_ui/managers/auth_manager.dart';
import 'package:nextsense_trial_ui/managers/firestore_manager.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

class AdhocSurvey implements RunnableSurvey {

  final CustomLogPrinter _logger = CustomLogPrinter('AdhocSurvey');

  final FirestoreManager _firestoreManager = getIt<FirestoreManager>();
  final AuthManager _authManager = getIt<AuthManager>();

  late Survey survey;

  RunnableSurveyType get type => RunnableSurveyType.adhoc;

  AdhocSurvey(this.survey);

  @override
  bool update({required SurveyState state,
    Map<String, dynamic>? data, bool persist = true}) {
    // Create new record only when we submit some data
    if (data != null) {
      save(data);
    }
    return true;
  }

  void save(Map<String, dynamic> data) {
    DateTime now = DateTime.now();
    String adhocProtocolKey = "${survey.id}_at_${now.millisecondsSinceEpoch}";
    _firestoreManager.queryEntity([
      Table.users,
      Table.adhoc_surveys
    ], [
      _authManager.getUserCode()!,
      adhocProtocolKey
    ]).then((firebaseEntity) {
      final record = AdhocSurveyRecord(firebaseEntity);
      record.setSurvey(survey.id);
      record.setTimestamp(now);
      record.setData(data);
      record.save();
    });
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
