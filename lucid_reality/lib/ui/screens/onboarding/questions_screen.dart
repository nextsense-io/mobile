import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucid_reality/domain/question.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
import 'package:lucid_reality/ui/screens/onboarding/onboarding_screen_vm.dart';
import 'package:lucid_reality/utils/text_theme.dart';
import 'package:lucid_reality/utils/utils.dart';

class QuestionsScreen extends HookWidget {
  final OnboardingScreenViewModel? viewModel;

  const QuestionsScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    ValueNotifier<List<Question>> questionsList = useState([]);
    final selectedIndex = useState(-1); // State variable to track selected index

    Future<List<Question>> allQuestions() async {
      final questions = <Question>[];
      questions.add(Question('Be more lucid during the day', Goal.moreLucid, false));
      questions.add(Question('Start lucid dreaming', Goal.startLucidDreaming, false));
      questions.add(
          Question('Learn how to relax and recharge during the day', Goal.learnRelaxingDay, false));
      questions.add(Question('Get better sleep at night', Goal.getBetterSleep, false));
      questions.add(Question('Promote and protect brain health', Goal.protectBrainHealth, false));
      questionsList.value = questions;
      return questionsList.value;
    }

    useEffect(() {
      var result = allQuestions();
      return () {
        result;
      };
    }, []);

    return Stack(
      children: [
        Container(
          color: NextSenseColors.backgroundColor,
          child: Image.asset(
            imageBasePath.plus("onboarding_questions_bg.png"),
            fit: BoxFit.fill,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Text(
                'What brings you to Lucid?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 32),
              Text(
                'I WANT TO...',
                style: Theme.of(context).textTheme.bodySmallWithFontWeight700FontSize12,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.separated(
                  itemCount: questionsList.value.length,
                  itemBuilder: (context, index) {
                    final question = questionsList.value[index];
                    question.isSelected = index == selectedIndex.value; // Check if item is selected
                    return InkWell(
                      onTap: () {
                        selectedIndex.value = index; // Update selected index
                        viewModel?.updateGoal(question.goal);
                      },
                      child: _rowQuestion(context, question),
                    );
                  },
                  separatorBuilder: (context, index) {
                    return const Divider(
                      thickness: 8,
                      color: Colors.transparent,
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _rowQuestion(BuildContext context, Question question) {
    return question.isSelected
        ? Container(
            padding: const EdgeInsets.all(24),
            decoration: ShapeDecoration(
              gradient: const RadialGradient(
                center: Alignment(0.07, 0.78),
                radius: 0,
                colors: NextSenseColors.purpleGradiantColors,
              ),
              shape: RoundedRectangleBorder(
                side: const BorderSide(width: 2, color: NextSenseColors.royalPurple),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              question.question,
              style: Theme.of(context).textTheme.bodyMediumWithFontWeight600,
            ),
          )
        : Container(
            padding: const EdgeInsets.all(24),
            decoration: ShapeDecoration(
              color: NextSenseColors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              shadows: const [
                BoxShadow(
                  color: NextSenseColors.transparentGray,
                  blurRadius: 4,
                  offset: Offset(0, 4),
                  spreadRadius: 0,
                )
              ],
            ),
            child: Text(
              question.question,
              style: Theme.of(context).textTheme.bodyMediumWithFontWeight600,
            ),
          );
  }
}
