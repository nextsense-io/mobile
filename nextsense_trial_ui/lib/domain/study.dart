import 'package:logging/logging.dart';
import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/domain/protocol/protocol.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

/**
 * Each entry corresponds to a field name in the database instance.
 */
enum StudyKey {
  // Determines if the study is currently active. If the study is inactive, new
  // data cannot be added to it.
  active,
  // Array of allowed protocols that can be recorded in this study.
  allowed_protocols,
  // Array of allowed surveys that can be started in this study.
  allowed_surveys,
  // Allow recording of adhoc protocols.
  adhoc_recording_allowed,
  // Allow adhoc surveys.
  adhoc_surveys_allowed,
  // Short study description to show in the home page.
  description,
  // Duration in days for a single subject.
  duration_days,
  //NextSense device earbuds configuration that is used in this study.
  earbuds_config,
  // Array of lines to show when enrolling a new patient in the study or
  // whenever they want to see it again.
  intro_text,
  // If medication tracking is enabled for this study.
  medication_tracking,
  // Name of the study.
  name,
  // Array of recording site organization ids where this study is running.
  recording_sites,
  // If seizure tracking is enabled for this study.
  seizure_tracking,
  // If side effects tracking is enabled for this study.
  side_effects_tracking,
  // If sleep tracking is enabled for this study.
  sleep_tracking,
  // Link to an image that can be shown in the intro page to this study.
  // Downloaded and cached locally.
  splash_page,
  // organization id of the main sponsor to this study.
  sponsor_id
}

class Study extends FirebaseEntity<StudyKey> {

  final CustomLogPrinter _logger = CustomLogPrinter('Study');

  Study(FirebaseEntity firebaseEntity) :
        super(firebaseEntity.getDocumentSnapshot());

  String getName() {
    return getValue(StudyKey.name) as String;
  }

  String getDescription() {
    return (getValue(StudyKey.intro_text) as List<dynamic>).map((e) => e as String).join("\n");
  }

  int getDurationDays() {
    return getValue(StudyKey.duration_days) as int;
  }

  String getEarbudsConfig() {
    return getValue(StudyKey.earbuds_config) as String;
  }

  List<ProtocolType> getAllowedProtocols() {
    List<dynamic> protocolNames = getValue(StudyKey.allowed_protocols) ?? [];
    List<ProtocolType> result = [];
    for (String name in protocolNames) {
      ProtocolType protocolType = protocolTypeFromString(name);
      if (protocolType == ProtocolType.unknown) {
        _logger.log(Level.WARNING, 'Unknown protocol "$name"');
        continue;
      }
      result.add(protocolType);
    }
    return result;
  }

  // Returns list of survey ids that are allowed
  List<String> getAllowedSurveys() {
    List<dynamic> surveyIds = getValue(StudyKey.allowed_surveys) ?? [];
    List<String> result = [];
    for (String surveyId in surveyIds) {
      result.add(surveyId);
    }
    return result;
  }

  // Allow recording of adhoc protocols
  bool get isAdhocRecordingAllowed {
    return getValue(StudyKey.adhoc_recording_allowed) == true;
  }

  bool get adhocSurveysAllowed {
    return getValue(StudyKey.adhoc_surveys_allowed) == true;
  }
}
