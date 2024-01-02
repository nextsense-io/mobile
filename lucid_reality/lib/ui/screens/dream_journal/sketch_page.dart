import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hand_signature/signature.dart';
import 'package:lucid_reality/ui/components/app_card.dart';
import 'package:lucid_reality/ui/components/svg_button.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';

import 'record_your_dream_vm.dart';

class SketchPage extends HookWidget {
  final RecordYourDreamViewModel viewModel;

  SketchPage(this.viewModel, {super.key});

  @override
  Widget build(BuildContext context) {
    final redoData = useRef(List.empty(growable: true));
    useEffect(() {
      viewModel.sketchControl.paths.clear();
      return null;
    }, []);
    return AppCard(
      Stack(
        fit: StackFit.expand,
        children: [
          HandSignature(
            control: viewModel.sketchControl,
            color: NextSenseColors.white,
            type: SignatureDrawType.shape,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            left: 0,
            child: Row(
              children: [
                SvgButton(
                  imageName: 'undo.svg',
                  onPressed: () {
                    if (viewModel.sketchControl.paths.isNotEmpty) {
                      redoData.value.add(viewModel.sketchControl.paths.last);
                      viewModel.sketchControl.stepBack();
                    }
                  },
                ),
                SizedBox(width: 16),
                SvgButton(
                  imageName: 'redo.svg',
                  onPressed: () {
                    if (redoData.value.isNotEmpty) {
                      viewModel.sketchControl.importPath([redoData.value.last]);
                      redoData.value.removeLast();
                    }
                  },
                ),
                Spacer(flex: 1),
                InkWell(
                  onTap: () {
                    viewModel.sketchControl.clear();
                    redoData.value.clear();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Clear',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: NextSenseColors.royalBlue),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
