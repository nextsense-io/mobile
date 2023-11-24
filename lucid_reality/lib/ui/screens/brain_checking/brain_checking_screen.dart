import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:lucid_reality/domain/brain_checking.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
import 'package:lucid_reality/ui/screens/brain_checking/brain_checking_vm.dart';
import 'package:lucid_reality/utils/utils.dart';
import 'package:stacked/stacked.dart';

class BrainCheckingScreen extends HookWidget {
  const BrainCheckingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder.reactive(
      viewModelBuilder: () => BrainCheckingViewModule(),
      onViewModelReady: (viewModel) => viewModel.init(),
      builder: (context, viewModel, child) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 56),
              Text(
                'Brain Check',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: ShapeDecoration(
                  color: NextSenseColors.cardBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Non-sleep deep rest',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: NextSenseColors.remSleep,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This exercise tests your reaction time and focus. Try to complete it at least once daily to gain into your brain\'s performance and the factors that affect it.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: Svg(imageBasePath.plus('btn_start.svg')),
                              fit: BoxFit.fill,
                            ),
                          ),
                          child: Text(
                            'Start',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'PREVIOUS RESULTS',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  itemBuilder: (context, index) {
                    final item = viewModel.brainCheckingResult[index];
                    return _rowBrainCheckingResultItem(context, item);
                  },
                  separatorBuilder: (context, index) {
                    return const Divider(
                      thickness: 8,
                      color: Colors.transparent,
                    );
                  },
                  itemCount: viewModel.brainCheckingResult.length,
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _rowBrainCheckingResultItem(BuildContext context, BrainChecking brainChecking) {
    return Container(
      height: 106,
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: NextSenseColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 82,
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(width: 1, color: NextSenseColors.remSleep),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 51,
                  height: 37,
                  child: Text(
                    'Oct 8, 2023',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600, color: NextSenseColors.deepSleep),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    '9:05am',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: NextSenseColors.deepSleep,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.only(left: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brainChecking.title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: brainChecking.type.getColor(),
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${brainChecking.spendTime}000ms',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12,
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
