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
            body: AppBody(
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
                      child: ListView.separated(
                        itemBuilder: (context, index) {
                          final dreamJournal = viewModel.dreamJournalList[index];
                          return rowDreamJournalListItem(context, dreamJournal);
                        },
                        separatorBuilder: (context, index) {
                          return Divider(
                            thickness: 8,
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
    return AppCard(
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
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
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
                Positioned(
                  top: 0,
                  right: 0,
                  child: Image(image: Svg(imageBasePath.plus('btn_edit_menu.svg'))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
