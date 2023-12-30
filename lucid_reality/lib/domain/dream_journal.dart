import 'package:lucid_reality/managers/firebase_realtime_db_entity.dart';

enum DreamJournalKey {
  id,
  createdAt,
  recordingPath,
  intentionMatchingRating,
  categoryID,
  intentID,
  note,
  title,
  description,
  isLucid,
  recordingDuration,
  tags,
  sketchPath
}

class DreamJournal extends FirebaseRealtimeDBEntity<DreamJournalKey> {
  static const String table = 'journals';

  DreamJournal();

  String? getId() {
    return getValue(DreamJournalKey.id);
  }

  void setId(String id) {
    setValue(DreamJournalKey.id, id);
  }

  int? getCreatedAt() {
    return getValue(DreamJournalKey.createdAt);
  }

  void setCreatedAt(int createAt) {
    setValue(DreamJournalKey.createdAt, createAt);
  }

  String? getRecordPath() {
    return getValue(DreamJournalKey.recordingPath);
  }

  void setRecordPath(String recordPath) {
    setValue(DreamJournalKey.recordingPath, recordPath);
  }

  String? getIntentionMatchingRating() {
    return getValue(DreamJournalKey.intentionMatchingRating);
  }

  void setIntentionMatchingRating(int intentionMatchingRating) {
    setValue(DreamJournalKey.intentionMatchingRating, intentionMatchingRating);
  }

  String? getCategoryID() {
    return getValue(DreamJournalKey.categoryID);
  }

  void setCategoryID(String? categoryID) {
    setValue(DreamJournalKey.categoryID, categoryID);
  }

  String? getIntentID() {
    return getValue(DreamJournalKey.intentID);
  }

  void setIntentID(String? intentID) {
    setValue(DreamJournalKey.intentID, intentID);
  }

  String? getNote() {
    return getValue(DreamJournalKey.note);
  }

  void setNote(String note) {
    setValue(DreamJournalKey.note, note);
  }

  String? getTitle() {
    return getValue(DreamJournalKey.title);
  }

  void setTitle(String title) {
    setValue(DreamJournalKey.title, title);
  }

  String? getDescription() {
    return getValue(DreamJournalKey.description);
  }

  void setDescription(String description) {
    setValue(DreamJournalKey.description, description);
  }

  bool? isLucid() {
    return getValue(DreamJournalKey.isLucid);
  }

  void setLucid(bool isLucid) {
    setValue(DreamJournalKey.isLucid, isLucid);
  }

  int? getRecordingDuration() {
    return getValue(DreamJournalKey.recordingDuration);
  }

  void setRecordingDuration(int recordingDuration) {
    setValue(DreamJournalKey.recordingDuration, recordingDuration);
  }

  String? getTags() {
    return getValue(DreamJournalKey.tags);
  }

  void setTags(String tags) {
    setValue(DreamJournalKey.tags, tags);
  }

  String? getSketchPath() {
    return getValue(DreamJournalKey.sketchPath);
  }

  void setSketchPath(String sketchPath) {
    setValue(DreamJournalKey.sketchPath, sketchPath);
  }

  factory DreamJournal.fromJson(MapEntry<String, dynamic> e) {
    DreamJournal dreamJournal = DreamJournal();
    dreamJournal.entityId = e.key;
    dreamJournal.setValues(Map.from(e.value));
    return dreamJournal;
  }
}
