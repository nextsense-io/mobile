import 'dart:io';

import 'package:nextsense_trial_ui/domain/firebase_entity.dart';
import 'package:nextsense_trial_ui/utils/android_logger.dart';

/// Each entry corresponds to a field name in the database instance.
enum StudyKey {
  // Allow recording of adhoc protocols.
  adhoc_recording_allowed,
  // Allow adhoc surveys.
  adhoc_surveys_allowed,
  // If new patients can be enrolled in this study.
  can_enroll_patients,
  // Short study description to show in the home page.
  description,
  // Duration in days for a single subject.
  duration_days,
  // NextSense device earbuds configuration that is used in this study.
  earbuds_config,
  // Array of screens to show when enrolling a new patient in the study or whenever they want to see
  // it again.
  intro,
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
  // Show signal visualization and analytics screens.
  show_signal_screens,
  // If sleep tracking is enabled for this study.
  sleep_tracking,
  // Link to an image that can be shown in the intro page to this study.
  // Downloaded and cached locally.
  splash_page_img_url,
  // Determines if the study is currently active. If the study is inactive, new data cannot be added
  // to it.
  status,
}

enum StudyStatusKey {
  not_started,
  active,
  finished
}

enum StudyIntroKey {
  // Title of the intro page.
  title,
  // Content text of the intro page.
  content,
  // Firebase Storage URL of the image to show in the intro page. Images need to be 1080 pixels wide
  // and 1024 pixels high.
  image_gs_url
}

// Content for a study introduction page.
class IntroPageContent {
  String title;
  String content;
  String imageGoogleStorageUrl;
  File? localCachedImage;

  IntroPageContent(this.title, this.content, this.imageGoogleStorageUrl);
}

class Study extends FirebaseEntity<StudyKey> {

  final CustomLogPrinter _logger = CustomLogPrinter('Study');

  Study(FirebaseEntity firebaseEntity) :
        super(firebaseEntity.getDocumentSnapshot());

  String getName() {
    return getValue(StudyKey.name) as String;
  }

  String getDescription() {
    return getValue(StudyKey.description) as String;
  }

  int getDurationDays() {
    return getValue(StudyKey.duration_days) as int;
  }

  String getEarbudsConfig() {
    return getValue(StudyKey.earbuds_config) as String;
  }

  bool showSignalScreens() {
    return getValue(StudyKey.show_signal_screens) == true;
  }

  // Allow recording of adhoc protocols
  bool get adhocRecordingAllowed {
    return getValue(StudyKey.adhoc_recording_allowed) == true;
  }

  bool get adhocSurveysAllowed {
    return getValue(StudyKey.adhoc_surveys_allowed) == true;
  }

  bool get seizureTrackingEnabled {
    return getValue(StudyKey.seizure_tracking) == true;
  }

  bool get sideEffectsTrackingEnabled {
    return getValue(StudyKey.side_effects_tracking) == true;
  }

  bool get medicationTrackingEnabled {
    return getValue(StudyKey.medication_tracking) == true;
  }

  List<IntroPageContent> getIntroPageContents() {
    List<dynamic>? introPages = getValue(StudyKey.intro);
    if (introPages == null) {
      return [];
    }
    return introPages.map((introPageMap) => IntroPageContent(introPageMap[StudyIntroKey.title.name],
        introPageMap[StudyIntroKey.content.name],
        introPageMap[StudyIntroKey.image_gs_url.name]))
        .toList();
  }
}
