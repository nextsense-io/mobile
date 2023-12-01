import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
import 'package:lucid_reality/utils/utils.dart';

import 'brain_checking_vm.dart';

class BrainCheckingScreen extends HookWidget {
  final BrainCheckingViewModule viewModel;

  const BrainCheckingScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final btnVisibility = useState(false);
    final controller = useAnimationController(duration: const Duration(seconds: 30));
    useEffect(() {
      controller.addStatusListener(
        (AnimationStatus status) {
          if (status == AnimationStatus.completed) {
            viewModel.navigateToBrainCheckingResultsPage();
          }
        },
      );
      viewModel.scheduleButtonVisibility();
      viewModel.btnVisibility = btnVisibility;
      return null;
    }, []);
    controller.forward();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: () {
                viewModel.redirectToBrainCheckingTab();
              },
              icon: Image.asset(
                imageBasePath.plus("close_button.png"),
                height: 34,
                width: 34,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Brain Check',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 23),
          Text(
            'TEST YOUR FOCUS AND REACTION TIME',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: ShapeDecoration(
                color: NextSenseColors.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              alignment: Alignment.center,
              child: btnVisibility.value
                  ? ElevatedButton(
                      onPressed: () {
                        viewModel.rescheduleButtonVisibility();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(360)),
                      ),
                      child: Container(
                        width: 131,
                        height: 131,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: Svg(imageBasePath.plus('btn_brain_check.svg')),
                            fit: BoxFit.fill,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const MyCountdown(Duration(milliseconds: 10)),
                      ),
                    )
                  : Text(
                      viewModel.brainChecking?.lastClickSpendTime ?? '',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
            ),
          ),
          const SizedBox(height: 30),
          Container(
            decoration: ShapeDecoration(
              color: NextSenseColors.remSleep,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            ),
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, animation) {
                return LinearProgressIndicator(
                  value: controller.value,
                  backgroundColor: NextSenseColors.remSleep,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class MyCountdown extends HookWidget {
  const MyCountdown(this.duration, {super.key});

  final Duration duration;

  @override
  build(BuildContext context) {
    final counter = useState(0);
    useInterval(
      () {
        counter.value += 10;
      },
      duration,
    );
    return Text(
      '${counter.value}ms',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  void useInterval(VoidCallback callback, Duration delay) {
    final savedCallback = useRef(callback);
    savedCallback.value = callback;
    useEffect(() {
      final timer = Timer.periodic(delay, (_) => savedCallback.value());
      return timer.cancel;
    }, [delay]);
  }
}
