import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucid_reality/domain/question.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
import 'package:lucid_reality/utils/utils.dart';

class QuestionsScreen extends HookWidget {
  const QuestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    ValueNotifier<List<Question>> questionsList = useState([]);
    final selectedIndex = useState(-1); // State variable to track selected index

    Future<List<Question>> allQuestions() async {
      final questions = <Question>[];
      questions.add(Question('Be more lucid during the day', false));
      questions.add(Question('Start lucid dreaming', false));
      questions.add(Question('Learn how to relax and recharge during the day', false));
      questions.add(Question('Get better sleep at night', false));
      questions.add(Question('Promote and protect brain health', false));
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
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.w700, fontSize: 12),
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
                colors: [Color(0xE09E1FF6), Color(0x386D2F98)],
              ),
              shape: RoundedRectangleBorder(
                side: const BorderSide(width: 2, color: Color(0xFF7336BA)),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              question.question,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          )
        : Container(
            padding: const EdgeInsets.all(24),
            decoration: ShapeDecoration(
              color: const Color(0xCC10142C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              shadows: const [
                BoxShadow(
                  color: Color(0x3F000000),
                  blurRadius: 4,
                  offset: Offset(0, 4),
                  spreadRadius: 0,
                )
              ],
            ),
            child: Text(
              question.question,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          );
  }
}
