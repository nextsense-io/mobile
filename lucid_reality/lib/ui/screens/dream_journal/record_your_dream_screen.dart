import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:lucid_reality/domain/dream_journal.dart';
import 'package:lucid_reality/ui/components/app_body.dart';
import 'package:lucid_reality/ui/components/app_card.dart';
import 'package:lucid_reality/ui/components/app_close_button.dart';
import 'package:lucid_reality/ui/components/app_text_buttton.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
import 'package:lucid_reality/ui/screens/dream_journal/audio_recoder_page.dart';
import 'package:lucid_reality/ui/screens/dream_journal/note_discription_page.dart';
import 'package:lucid_reality/ui/screens/dream_journal/record_your_dream_vm.dart';
import 'package:lucid_reality/ui/screens/dream_journal/sketch_page.dart';
import 'package:lucid_reality/utils/utils.dart';
import 'package:stacked/stacked.dart';

class RecordYourDreamScreen extends HookWidget {
  static const String id = 'record_your_dream_screen';

  const RecordYourDreamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tabController = useTabController(initialLength: 3, initialIndex: 0);
    final selectedTabIndex = useState(0);
    final titleController = useTextEditingController();
    final tagsController = useTextEditingController();
    final isLucid = useState<bool>(false);
    final isTitleEditable = useState(true);
    final isTagsEditable = useState(true);
    final isEditMode = useRef(false);
    return ViewModelBuilder.reactive(
      viewModelBuilder: () => RecordYourDreamViewModel(),
      onViewModelReady: (viewModel) {
        viewModel.init();
        if (ModalRoute.of(context)?.settings.arguments is int) {
          viewModel.intentionMatchRating = ModalRoute.of(context)?.settings.arguments as int;
        }
        final dreamJournal = ModalRoute.of(context)?.settings.arguments;
        if (dreamJournal is DreamJournal) {
          Future.delayed(
            Duration(milliseconds: 500),
            () {
              isEditMode.value = true;
              viewModel.setDreamJournal(dreamJournal);
              titleController.text = dreamJournal.getTitle() ?? '';
              isTitleEditable.value = !titleController.text.isNotEmpty;
              tagsController.text = dreamJournal.getTags() ?? '';
              isTagsEditable.value = !titleController.text.isNotEmpty;
              viewModel.tagValueListener(tagsController.text);
              isLucid.value = dreamJournal.isLucid() ?? false;
            },
          );
        }
      },
      builder: (context, viewModel, child) {
        return SafeArea(
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              backgroundColor: NextSenseColors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              actions: [
                AppCloseButton(
                  onPressed: () {
                    viewModel.goBack();
                  },
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
                      'Record your dream',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Lucid dreams are a lot more rewarding if you consciously aim to achieve an objective before you go to sleep.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    SizedBox(height: 27),
                    Container(
                      decoration: ShapeDecoration(
                        color: NextSenseColors.cardBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(33),
                        ),
                      ),
                      child: TabBar(
                        onTap: (value) {
                          selectedTabIndex.value = value;
                        },
                        indicator: BoxDecoration(
                          image: DecorationImage(
                            image: Svg(imageBasePath.plus('tab_active_bg.svg')),
                            fit: BoxFit.contain,
                          ),
                        ),
                        indicatorPadding: EdgeInsets.symmetric(horizontal: 8),
                        padding: EdgeInsets.zero,
                        indicatorWeight: double.minPositive,
                        labelColor: NextSenseColors.white,
                        labelStyle: Theme.of(context).textTheme.bodySmall,
                        unselectedLabelColor: NextSenseColors.royalBlue,
                        unselectedLabelStyle: Theme.of(context).textTheme.bodySmall,
                        controller: tabController,
                        tabs: [
                          Tab(
                            text: "Note",
                          ),
                          Tab(
                            text: "Audio",
                          ),
                          Tab(
                            text: "Sketch",
                          )
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      textCapitalization: TextCapitalization.sentences,
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.bodySmall,
                      controller: titleController,
                      enabled: isTitleEditable.value,
                      decoration: InputDecoration(
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        contentPadding: const EdgeInsets.all(16.00),
                        alignLabelWithHint: true,
                        label: const Text('Title'),
                        filled: true,
                        fillColor: NextSenseColors.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none,
                        ),
                        labelStyle: Theme.of(context).textTheme.bodySmall,
                      ),
                      onChanged: viewModel.titleValueListener,
                    ),
                    SizedBox(height: 8),
                    Flexible(
                      child: IndexedStack(
                        index: selectedTabIndex.value,
                        children: [
                          Visibility(
                            maintainState: true,
                            visible: selectedTabIndex.value == 0,
                            child: NoteDescriptionPage(viewModel),
                          ),
                          Visibility(
                            visible: selectedTabIndex.value == 1,
                            maintainState: true,
                            child: AudioRecorderPage(viewModel),
                          ),
                          Visibility(
                            visible: selectedTabIndex.value == 2,
                            maintainState: true,
                            child: SketchPage(viewModel),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.bodySmall,
                      controller: tagsController,
                      enabled: isTagsEditable.value,
                      decoration: InputDecoration(
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        contentPadding: const EdgeInsets.all(16.00),
                        alignLabelWithHint: true,
                        filled: true,
                        label: const Text('Tags'),
                        fillColor: NextSenseColors.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide.none,
                        ),
                        labelStyle: Theme.of(context).textTheme.bodySmall,
                      ),
                      onChanged: viewModel.tagValueListener,
                    ),
                    SizedBox(height: 8),
                    AppCard(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Lucid',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Switch.adaptive(
                            activeColor: NextSenseColors.royalPurple,
                            value: isLucid.value,
                            onChanged: isEditMode.value
                                ? (value) {
                                    if (viewModel.dreamJournal?.isLucid() == false) {
                                      isLucid.value = value;
                                    }
                                  }
                                : (value) => isLucid.value = value,
                          )
                        ],
                      ),
                    ),
                    SizedBox(height: 19),
                    Align(
                      alignment: Alignment.centerRight,
                      child: AppTextButton(
                        text: 'Save Entry',
                        onPressed: viewModel.isValidForSavingData || isEditMode.value
                            ? () {
                                if (isEditMode.value) {
                                  viewModel.updateRecord(isLucid.value);
                                } else {
                                  viewModel.saveRecord(isLucid.value);
                                }
                              }
                            : null,
                        backgroundImage: 'btn_save_entry.svg',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
