import 'dart:io';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_common/utils/android_logger.dart';
import 'package:hand_signature/signature.dart';
import 'package:logging/logging.dart';
import 'package:lucid_reality/di.dart';
import 'package:lucid_reality/domain/dream_journal.dart';
import 'package:lucid_reality/managers/firebase_storage_manager.dart';
import 'package:lucid_reality/managers/storage_manager.dart';
import 'package:lucid_reality/ui/screens/reality_check/reality_check_base_vm.dart';
import 'package:lucid_reality/utils/duration.dart';

import 'dream_journal_screen.dart';

class RecordYourDreamViewModel extends RealityCheckBaseViewModel {
  final _logger = CustomLogPrinter('RecordYourDreamViewModel');
  final StorageManager _storageManager = getIt<StorageManager>();
  final FirebaseStorageManager _firebaseStorageManager = getIt<FirebaseStorageManager>();
  final assetsAudioPlayer = AssetsAudioPlayer();
  File? recordingFile;
  final recordedDuration = ValueNotifier(0);
  final sketchControl = HandSignatureControl(
    threshold: 3.0,
    smoothRatio: 0.65,
    velocityRange: 2.0,
  );
  String _title = '';
  String _description = '';
  String _tags = '';
  bool isValidForSavingData = false;
  int intentionMatchRating = 0;

  @override
  void init() {
    super.init();
    sketchControl.addListener(
      () {
        validateSaveEntryButton();
      },
    );
  }

  String getNewRecordingFilePath() {
    recordingFile = _storageManager.getNewRecordingFile();
    return recordingFile!.absolute.path;
  }

  void playOrPause() async {
    try {
      _logger.log(Level.INFO, '${assetsAudioPlayer.current.hasValue}');
      if (!assetsAudioPlayer.current.hasValue) {
        assetsAudioPlayer.open(Audio.file(recordingFile!.absolute.path));
      } else {
        if (assetsAudioPlayer.current.value?.audio.assetAudioPath.compareTo(recordingFile!.path) !=
            0) {
          assetsAudioPlayer.open(Audio.file(recordingFile!.absolute.path));
        } else {
          assetsAudioPlayer.playOrPause();
        }
      }
      recordedDuration.value = assetsAudioPlayer.current.value!.audio.duration.inSeconds;
      notifyListeners();
    } catch (t) {
      print(t);
    }
  }

  void pauseMusic() {
    if (assetsAudioPlayer.isPlaying.value) {
      assetsAudioPlayer.pause();
    }
  }

  @override
  void dispose() {
    super.dispose();
    try {
      pauseMusic();
      assetsAudioPlayer.dispose();
    } catch (e) {
      print(e);
    }
  }

  void deleteRecordingOnExist() {
    try {
      if (recordingFile != null) {
        recordingFile?.delete();
        recordingFile = null;
        pauseMusic();
        if (assetsAudioPlayer.current.value?.audio != null) {
          assetsAudioPlayer.playlist?.remove(assetsAudioPlayer.current.value?.audio as Audio);
        }
        recordedDuration.value = 0;
        validateSaveEntryButton();
      }
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }

  void addDuration(int duration) {
    recordedDuration.value += duration;
    notifyListeners();
  }

  void validateSaveEntryButton() {
    isValidForSavingData = _title.isNotEmpty &&
        (_description.isNotEmpty || recordingFile != null || sketchControl.paths.isNotEmpty);
    notifyListeners();
  }

  void titleValueListener(String value) {
    this._title = value.trim();
    validateSaveEntryButton();
  }

  void descriptionValueListener(String value) {
    this._description = value.trim();
    validateSaveEntryButton();
  }

  void tagValueListener(String value) {
    this._tags = value.trim();
    validateSaveEntryButton();
  }

  void saveRecord(bool isLucid) async {
    setBusy(true);
    // Checking sketch data
    String? sketchGSUrl;
    if (sketchControl.paths.isNotEmpty) {
      final imageData = await sketchControl.toImage();
      if (imageData != null) {
        final File sketchFile = await _storageManager.writeToFile(imageData);
        sketchGSUrl = await _firebaseStorageManager.uploadDrawingFile(sketchFile);
      }
    }
    String? recordingGSUrl;
    if (recordingFile != null) {
      recordingGSUrl = await _firebaseStorageManager.uploadRecordingFile(recordingFile!);
    }
    final DreamJournal dreamJournal = DreamJournal();
    dreamJournal.setCreatedAt(DateTime.now().millisecondsSinceEpoch);
    dreamJournal.setTitle(_title);
    dreamJournal.setDescription(_description);
    dreamJournal.setTags(_tags);
    if (recordingGSUrl != null) {
      dreamJournal.setRecordPath(recordingGSUrl);
    }
    if (recordedDuration.value != 0) {
      dreamJournal.setDescription(formatDuration(Duration(seconds: recordedDuration.value)));
    }
    if (sketchGSUrl != null) {
      dreamJournal.setSketchPath(sketchGSUrl);
    }
    dreamJournal.setLucid(isLucid);
    if (intentionMatchRating != 0) {
      dreamJournal.setIntentionMatchingRating(intentionMatchRating);
    }
    dreamJournal.setCategoryID(lucidManager.intentEntity.getCategoryID());
    dreamJournal.setIntentID(lucidManager.intentEntity.getId());
    await lucidManager.saveDreamJournalRecord(dreamJournal);
    setBusy(false);
    navigation.popUntil(DreamJournalScreen.id);
  }
}
