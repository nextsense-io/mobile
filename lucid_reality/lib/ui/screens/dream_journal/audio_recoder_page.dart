import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucid_reality/ui/components/app_card.dart';
import 'package:lucid_reality/ui/components/app_circular_progress_bar.dart';
import 'package:lucid_reality/ui/components/svg_button.dart';
import 'package:lucid_reality/ui/screens/dream_journal/record_your_dream_vm.dart';
import 'package:lucid_reality/utils/custom_hooks.dart';
import 'package:lucid_reality/utils/duration.dart';
import 'package:record/record.dart';

class AudioRecorderPage extends HookWidget {
  final RecordYourDreamViewModel viewModel;

  const AudioRecorderPage(this.viewModel, {super.key});

  @override
  Widget build(BuildContext context) {
    final recorder = useAudioController();
    final isRecording = useState(false);
    final isEditMode = useRef(viewModel.dreamJournal?.hasRecording() == true);
    if (isRecording.value) {
      useInterval(
        () {
          viewModel.addDuration(1);
        },
        Duration(seconds: 1),
      );
    }
    return AppCard(
      Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: double.maxFinite,
            height: 16,
          ),
          isRecording.value
              ? AppCircularProgressBar(
                  size: Size(120, 120),
                  text: isEditMode.value
                      ? viewModel.dreamJournal?.getRecordingDuration() ?? '00:00'
                      : formatDuration(Duration(seconds: viewModel.recordedDuration.value)),
                )
              : viewModel.assetsAudioPlayer.builderCurrentPosition(
                  builder: (context, duration) {
                    var progressBarPercentage = 0.0;
                    var isSameAudio = viewModel.isCurrentRecordingPlaying() || isEditMode.value;
                    if (viewModel.assetsAudioPlayer.current.hasValue && isSameAudio) {
                      progressBarPercentage = duration.inSeconds /
                          (viewModel.assetsAudioPlayer.current.value?.audio.duration.inSeconds ??
                              1);
                      progressBarPercentage = 1 - progressBarPercentage;
                    }
                    return AppCircularProgressBar(
                      size: Size(120, 120),
                      value: progressBarPercentage,
                      text: isSameAudio ? formatDuration(duration) : '00.00',
                    );
                  },
                ),
          isEditMode.value
              ? viewModel.assetsAudioPlayer.builderIsPlaying(
                  builder: (context, isPlaying) {
                    return Container(
                      alignment: Alignment.center,
                      child: SvgButton(
                        imageName: isPlaying ? 'ic_pause.svg' : 'ic_play.svg',
                        onPressed: () {
                          viewModel.playOrPauseFromUrl(
                              '${viewModel.dreamJournal?.getRecordingPath()}');
                        },
                      ),
                    );
                  },
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Visibility(
                      visible: !isRecording.value && viewModel.recordingFile != null,
                      child: SvgButton(
                        imageName: 'ic_delete.svg',
                        onPressed: () {
                          viewModel.deleteRecordingOnExist();
                        },
                      ),
                    ),
                    SvgButton(
                      size: Size(50, 50),
                      imageName: isRecording.value ? 'ic_pause.svg' : 'ic_recording.svg',
                      onPressed: () async {
                        // Check and request permission if needed
                        if (isRecording.value) {
                          if (await recorder.isRecording()) {
                            await recorder.stop();
                          }
                          isRecording.value = false;
                          viewModel.validateSaveEntryButton();
                        } else {
                          //Delete recorded file if exist
                          viewModel.deleteRecordingOnExist();
                          if (await recorder.hasPermission()) {
                            // Start recording to file
                            await recorder.start(const RecordConfig(),
                                path: viewModel.getNewRecordingFilePath());
                            isRecording.value = true;
                          }
                        }
                      },
                    ),
                    Visibility(
                      visible: !isRecording.value && viewModel.recordingFile != null,
                      child: viewModel.assetsAudioPlayer.builderIsPlaying(
                        builder: (context, isPlaying) {
                          return SvgButton(
                            imageName: isPlaying ? 'ic_pause.svg' : 'ic_play.svg',
                            onPressed: () {
                              viewModel.playOrPause();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                )
        ],
      ),
    );
  }
}
