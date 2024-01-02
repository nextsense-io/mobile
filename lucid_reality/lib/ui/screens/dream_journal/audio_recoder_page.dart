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
    final record = useAudioController();
    final isRecording = useState(false);
    if (isRecording.value) {
      useInterval(
        () {
          viewModel.addDuration(1);
        },
        Duration(seconds: 1),
      );
    }
    return AppCard(
      Stack(
        children: [
          Positioned(
            top: 60,
            bottom: 100,
            left: 0,
            right: 0,
            child: isRecording.value
                ? AppCircularProgressBar(
                    size: Size(150, 150),
                    value: 100,
                    text: formatDuration(Duration(seconds: viewModel.recordedDuration.value)),
                  )
                : viewModel.assetsAudioPlayer.builderCurrentPosition(
                    builder: (context, duration) {
                      return AppCircularProgressBar(
                        size: Size(150, 150),
                        value: viewModel.recordingFile != null
                            ? duration.inSeconds / viewModel.recordedDuration.value
                            : 0,
                        text: formatDuration(duration),
                      );
                    },
                  ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Row(
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
                      if (await record.isRecording()) {
                        await record.stop();
                      }
                      isRecording.value = false;
                      viewModel.validateSaveEntryButton();
                    } else {
                      //Delete recorded file if exist
                      viewModel.deleteRecordingOnExist();
                      if (await record.hasPermission()) {
                        // Start recording to file
                        await record.start(const RecordConfig(),
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
            ),
          )
        ],
      ),
    );
  }
}
