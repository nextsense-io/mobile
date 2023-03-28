import 'package:nextsense_trial_ui/domain/firebase_entity.dart';

enum SurveyResultKey {
  user_id,
  study_id,
  survey_id,
  planned_survey_id,
  scheduled_survey_id,
  start_datetime,  // When the survey was started.
  end_datetime,  // When the survey was completed.
  updated_at,  // When a completed survey was updated.
  data,  // Survey data as a Map of key/values, with the key corresponding to a question id.
}

class SurveyResult extends FirebaseEntity<SurveyResultKey> {

  SurveyResult(FirebaseEntity firebaseEntity) :
        super(firebaseEntity.getDocumentSnapshot(), addMonitoringFields: false);

  void setUserId(String userId) {
    setValue(SurveyResultKey.user_id, userId);
  }

  void setStudyId(String studyId) {
    setValue(SurveyResultKey.study_id, studyId);
  }

  void setSurveyId(String surveyId) {
    setValue(SurveyResultKey.survey_id, surveyId);
  }

  void setPlannedSurveyId(String plannedSurveyId) {
    setValue(SurveyResultKey.planned_survey_id, plannedSurveyId);
  }

  void setScheduledSurveyId(String scheduledSurveyId) {
    setValue(SurveyResultKey.scheduled_survey_id, scheduledSurveyId);
  }

  void setStartDateTime(DateTime startDateTime) {
    setValue(SurveyResultKey.start_datetime, startDateTime);
  }

  void setEndDateTime(DateTime endDateTime) {
    setValue(SurveyResultKey.end_datetime, endDateTime);
  }

  void setUpdatedAt(DateTime updatedAt) {
    setValue(SurveyResultKey.updated_at, updatedAt);
  }

  void setData(Map<String, dynamic> data) {
    setValue(SurveyResultKey.data, data);
  }

  String? getUserId() {
    return getValue(SurveyResultKey.user_id);
  }

  String? getStudyId() {
    return getValue(SurveyResultKey.study_id);
  }

  String? getSurveyId() {
    return getValue(SurveyResultKey.survey_id);
  }

  String? getPlannedSurveyId() {
    return getValue(SurveyResultKey.planned_survey_id);
  }

  String? getScheduledSurveyId() {
    return getValue(SurveyResultKey.scheduled_survey_id);
  }

  DateTime? getStartDateTime() {
    return getValue(SurveyResultKey.start_datetime);
  }

  DateTime? getEndDateTime() {
    return getValue(SurveyResultKey.end_datetime);
  }

  DateTime? getUpdatedAt() {
    return getValue(SurveyResultKey.updated_at);
  }

  Map<String, dynamic>? getData() {
    return getValue(SurveyResultKey.data);
  }
}