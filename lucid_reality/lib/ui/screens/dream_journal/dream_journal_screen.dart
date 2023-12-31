import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:lucid_reality/domain/dream_journal.dart';
import 'package:lucid_reality/ui/components/app_body.dart';
import 'package:lucid_reality/ui/components/app_card.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
import 'package:lucid_reality/ui/screens/dream_journal/dream_journal_vm.dart';
import 'package:lucid_reality/utils/date_utils.dart';
import 'package:lucid_reality/utils/text_theme.dart';
import 'package:lucid_reality/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:stacked/stacked.dart';

class DreamJournalScreen extends HookWidget {
  static const String id = 'dream_journal_screen';

  const DreamJournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder.reactive(
      viewModelBuilder: () => DreamJournalViewModel(),
      onViewModelReady: (viewModel) => viewModel.init(),
      builder: (context, viewModel, child) {
        return SafeArea(
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: NextSenseColors.transparent,
              elevation: 0,
              leading: InkWell(
                onTap: () {
                  viewModel.goBack();
                },
                child: Transform.rotate(
                  angle: 180 * math.pi / 180,
                  child: Image(
                    image: Svg(imageBasePath.plus('forward_arrow.svg')),
                  ),
                ),
              ),
              actions: [
                InkWell(
                  onTap: () {
                    viewModel.navigateToDreamConfirmationScreen();
                  },
                  child: Image(
                    image: Svg(imageBasePath.plus('ic_add.svg')),
                  ),
                )
              ],
            ),
            body: AppBody(
              isLoading: viewModel.isBusy,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dream Journal',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'A collection of all your recorded dreams.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    SizedBox(height: 26),
                    Expanded(
                      child: viewModel.dreamJournalList.isEmpty
                          ? buildEmptyView(context)
                          : ListView.separated(
                              itemBuilder: (context, index) {
                                final dreamJournal = viewModel.dreamJournalList[index];
                                return rowDreamJournalListItem(context, dreamJournal);
                              },
                              separatorBuilder: (context, index) {
                                return Divider(
                                  thickness: 8,
                                  color: Colors.transparent,
                                );
                              },
                              itemCount: viewModel.dreamJournalList.length,
                            ),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget rowDreamJournalListItem(BuildContext context, DreamJournal dreamJournal) {
    return Stack(
      children: [
        AppCard(
          Row(
            children: [
              Container(
                width: 80,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(width: 1, color: NextSenseColors.royalBlue),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      dreamJournal.getCreatedAt()?.toDate().getDate() ?? '',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMediumWithFontWeight600
                          ?.copyWith(color: NextSenseColors.skyBlue),
                    ),
                    SizedBox(height: 12),
                    Image(image: Svg(imageBasePath.plus('lucid.svg'))),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      overflow: TextOverflow.ellipsis,
                      dreamJournal.getTitle() ?? '',
                      style: Theme.of(context).textTheme.bodySmallWithFontWeight600,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      overflow: TextOverflow.ellipsis,
                      dreamJournal.getDescription() ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: Image(image: Svg(imageBasePath.plus('btn_edit_menu.svg'))),
        ),
      ],
    );
  }

  Widget buildEmptyView(BuildContext context) {
    final viewModel = context.watch<DreamJournalViewModel>();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Start journaling your dream now',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                side: const BorderSide(width: 1, color: NextSenseColors.royalPurple),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              viewModel.navigateToDreamConfirmationScreen();
            },
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: ShapeDecoration(
                gradient: const RadialGradient(
                  center: Alignment(0.07, 0.78),
                  radius: 0,
                  colors: NextSenseColors.purpleGradiantColors,
                ),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(width: 1, color: NextSenseColors.royalPurple),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'CREATE NEW',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmallWithFontWeight700,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
