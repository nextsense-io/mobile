import 'package:lucid_reality/domain/article.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';

class ArticleManager {
  final List<Article> articles = List.empty(growable: true);

  List<InsightLearnItem> getInsightLearnItems() {
    return [
      InsightLearnItem(
        'Non-sleep deep rest',
        'ic_rest.svg',
        NextSenseColors.coral,
        Article(
          'Non-sleep deep rest',
          _buildNonSleepDeepRestDescription(),
          'ic_learn_3.png',
        ),
      ),
      InsightLearnItem(
        'Tips for better sleep',
        'ic_tips.svg',
        NextSenseColors.royalPurple,
        Article(
          'Adjust your mindset and get better sleep',
          _buildTipsForBetterSleepDescription(),
          'ic_learn_1.png',
        ),
      ),
      InsightLearnItem(
        'Top napping questions',
        'ic_question_mark.svg',
        NextSenseColors.skyBlue,
        Article(
          'Top Napping FAQs',
          _buildTopNappingQuestionsDescription(),
          'ic_learn_4.png',
        ),
      ),
    ];
  }

  Future prepareArticles() async {
    articles.add(
      Article(
        'What is lucidity?',
        _buildLucidityDescription(),
        'ic_learn_0.png',
      ),
    );
    articles.add(
      Article(
        'Adjust your mindset and get better sleep',
        _buildTipsForBetterSleepDescription(),
        'ic_learn_1.png',
      ),
    );
    articles.add(
      Article(
        'Lucid dreams and intentions',
        _buildLucidDreamsAndIntentionsDescription(),
        'ic_learn_2.png',
      ),
    );
    articles.add(
      Article(
        'Non-sleep deep rest',
        _buildNonSleepDeepRestDescription(),
        'ic_learn_3.png',
      ),
    );
    articles.add(
      Article(
        'Top Napping FAQs',
        _buildTopNappingQuestionsDescription(),
        'ic_learn_4.png',
      ),
    );
    articles.add(
      Article(
        'Are you using your Apple Watch correctly?',
        _buildAppleWatchGuideDescription(),
        'ic_learn_5.png',
      ),
    );
    articles.add(
      Article(
        'Lucid dreams can improve mood',
        _buildStudyAboutLucidDreamsDescription(),
        'ic_learn_6.png',
      ),
    );
  }

  String _buildLucidityDescription() {
    return '''
Picture a moment of absolute clarity and alertness, where distractions dissolve and the present engulfs you entirely. In this moment you are truly awake—you are lucid.

If such a peaceful, present state sounds unrepeatable, you’re not alone. High rates of attention challenges, exhaustion, and stress means that few of us are living lucidly—a troubling fact when we consider the consequential decisions we face as individuals and a society.

Fortunately, a more lucid life is accessible. In this article, we dive deeper into the meaning of lucidity, the science behind it, and how to achieve it.

What Does It Mean to Be Lucid?
The basic components of lucidity can be summarized as follows:

• You’re fully awake and alert. Lucidity entails being awake, not just physically, but mentally. It means being attentive, energized, and aware of your surroundings.

• You’re present in the moment. When lucid, you are completely present and immersed in the here and now. Free from unproductive thoughts and emotions, you devote all your mental resources to the task at hand

The Science of Lucidity: Understanding the Consciousness Continuum
Consider your experience of the world the moment you wake up. Is it the same as your experience an hour later? What about when you’re completely in the zone at work? Or, by contrast, navigating brain fog? In all of these states, you are technically awake, but your degree of lucidity varies.

These subjective states are reflected in your brain. Using electroencephalography (EEG)—a technique for measuring the brain’s electrical dynamics—researchers have found that brainwave patterns change throughout the course of the day and according to lucidity.

While asleep and just after waking, slower theta and delta waves typically are more dominant. Gradually, these rhythms give way  to faster alpha and beta waves, which are associated with wakefulness and alertness. This transition is not always instantaneous, and the "groggy" feeling experienced upon waking is a manifestation of this gradual shift in brainwave activity. As time passes and you become more active, most people experience greater lucidity, marked by higher beta wave activity in the brain. You can enhance this effect through exercise or caffeine, which have been shown to promote beta waves.

Studies reveal that specific brainwave patterns characterize extreme focus or flow states; others coincide with drowsiness. In addition to changing over the course of the day, brainwave patterns change over the course of a lifetime, with certain patterns predicting a decline in memory and cognitive performance. Understanding the intricacies of brain activity patterns and their correlation with mental states can help us optimize our cognitive performance and enhance our overall level of lucidity.
    '''
        .trim();
  }

  String _buildTipsForBetterSleepDescription() {
    return """
The pursuit of amazing sleep can, paradoxically, be terrible for sleep. Though plenty of people benefit from tracking devices and sleep optimization techniques, others find that these measures put undue pressure on the process, making good sleep even more elusive. That’s why we suggest working on your sleep mindset alongside any other interventions. Here are some mindset tips, based on the work of sleep psychologist Stephanie Romiszewski and others.

• Stop seeking perfection. Abandon the idea of a perfect night’s sleep, and be kind to yourself if you don’t hit your sleep goals. Know that even if you get 0 sleep tonight, you’ll be ok in the long run.

• Celebrate your uniqueness. Everyone has different sleep needs, so a 10PM-6AM schedule may not work for you. Don't force your body into a pattern that feels unnatural. If you organically fall asleep late or wake up early, enjoy that time!

• Think in terms of sleep 'opportunities' rather than a strict bedtime. Creating sleep opportunities means carving out a consistent time window devoted to sleep—without enforcing a rigid bedtime. For example, you might aim to be ready for bed by 11 PM every night, but if you're not sleepy at that time, it’s totally fine to stay up until you feel tired. (Just make sure you’re not doing anything excessively stimulating).

• Don't stress nighttime wake-ups. Waking up during the night is normal and doesn't mean your sleep is ruined. When this happens, relax in your bed for a few minutes and take pleasure in the calm of the night. If you don’t fall back asleep, get up and do something you enjoy until you feel tired again.
    """
        .trim();
  }

  String _buildLucidDreamsAndIntentionsDescription() {
    return """
A lucid dream is one in which you know you’re dreaming—it’s that simple. Training your brain to achieve that kid of awareness is a bit less simple, but most people can get there with practice. One component of that practice involves setting an intention before you go to sleep.

If you practice yoga, meditation, or another form of mindfulness, you may be familiar with intention setting. In those contexts, intention connotes a direction or goal to which you devote mental resources to (e.g., gratitude), giving the practice added purpose. Intention setting for dreams has a similar function. By directing your mind toward a topic before bed, you may nudge your brain to further explore that topic as you sleep.

An intention can be something fun (e.g., “I want to fly in my dream!”) or something with psychological depth (e.g., I want to revisit an upsetting event from my childhood). Of course, simply asking your mind to take a particular journey overnight doesn’t guarantee it’s going to happen, or that you’ll become lucid if it does. To maximize your chances of success try the following:

    • Make remembering part of the intention. If you’re new to lucid dreaming, consider starting with the following intention: “Tonight, I want to remember my dreams.” Like any intention, you can set this one by mentally repeating it in you head and/or by writing it down in a dream journal next to your bed.

    • Perform reality checks. One shortcut to becoming lucid at night is to complete reality checks throughout the day. This involves performing some cognitive task that tends to unfold differently in dreams versus reality. For example, you might try to count your fingers every few hours during the day; then, when you try the same task during your dream, you might come up with a different number, prompting the realization that it’s a dream.

    • Visualize the dream you want to have. Before bed, take time to rehearse the dream you want to have. If it is conversing with a loved one (living or deceased) imagine yourself having the conversation. What are you wearing? Where is the conversation taking place? What’s the weather like? How do you feel? Etc.The more emotion you can conjure, the more likely you are to dream in the direction of the intention.

Remember, lucid dreaming takes practice. So if your intentions don’t immediately translate into lucid experiences, be patient—it’s worth the wait.
    """
        .trim();
  }

  String _buildNonSleepDeepRestDescription() {
    return """
Non-sleep deep rest, or NSDR, is more or less what it sounds like: a way to give your brain a meaningful break, without fully falling asleep. By inducing deep relaxation, NSDR can help you rest, refocus, and recharge midday. Championed by neuroscientist Andrew Huberman, it’s particularly useful for people who struggle with other relaxation techniques, such as naps or meditation.

How do I do it?
If you’re new to NSDR, we recommend this 4-step approach:

1. Sit or recline in a comfy position.
2. Put on your headphones and play relaxing music.
3. Set a timer for 10 minutes.
4. Close your eyes until the timer goes off.


That’s it! Don’t try to fall asleep or enter some zen state. Simply allow yourself to do nothing, without any particular goal. Once you’re used to the practice, you can incorporate some of the more structured techniques mentioned below. Over time, you may also want to adjust the length of your sessions (we recommend anywhere from 10 to 30 minutes).

Structured NSDR
If you’d ready for a more structured approach to NSDR (or need something to do while you’re lying there!), add one or or both of the following to your practice:

• Body scan: Bring your attention to different parts of your body, starting from your toes and working up to the top of your head. Notice any tension (e.g, a clenched jaw or fists) and try to release that tension.

• Breath work: Start by focusing on your breath’s natural rhythm, without altering it. After a few minutes of natural breathing, introduce the 4-7-8 technique: inhale for 4 counts, hold your breath for 7 counts, and exhale for 8 counts. Maintain this pattern as long as desired.

What if I fall asleep?
Like NSDR, naps are a great way to rest and recharge, so if your session turns into a nap, that’s fine! We recommend setting a timer for your NSDR session, so that can double as an alarm if you do nod off.
    """
        .trim();
  }

  String _buildTopNappingQuestionsDescription() {
    return """
Wondering whether you should take up napping? Already a napper and want to get more out of your daily snooze? We’ve got you covered.

Q: How long should my nap be?
• 15-20 minutes is the ideal nap duration, as longer naps can make you feel groggy when you wake up.

Q: Are there any risks to napping?
• For many people, naps can be a great way to relax and recharge. But if you have difficulty falling asleep at night, nap with caution! Late or extended naps can disrupt nighttime sleep.

Q: What’s the best time of day to nap?
• For most, the best time to nap is around 2PM, during a natural circadian dip. Still, circadian rhythms vary from person to person and, thus, so do optimal nap times

Q: Nap? Coffee? Both?
• Both caffeine and naps can increase energy and focus. Naps may be preferable as they’re free and don’t come with side effects. You can also combine the two with a "coffee nap"— consume caffeine before a 15-20 minute nap and its effects should kick in right as you’re waking up.

Q: Can a nap replace lost nighttime sleep?
• Not fully. While refreshing, naps can't substitute the benefits of a full night's sleep.

Q: Is it okay to nap every day?
• If it doesn't affect nighttime sleep and fits your routine, go for it!
    """
        .trim();
  }

  String _buildAppleWatchGuideDescription() {
    return """
If you have an Apple watch, then you have the ability to track and improve your sleep. To get the most out of this tool, be sure to correctly configure your sleep settings in Apple Health. Even if you’ve been tracking sleep for some time, we recommend reviewing these steps, as your settings may be outdated.

Getting started

1. Make sure your phone is running the latest version of iOS (and if it isn’t, update it!).

2. Open the Health app.

3. Navigate to sleep settings. Tap on the "Browse" tab at the bottom right, then select "Sleep."

4. Set your sleep goals. Tap on "Get Started" under "Set Up Sleep” and create sleep goals. This is the total amount of sleep you aim to get each night. For most people, a healthy number is 7 to 9 hours.

5. Create your schedule. When do you typically go to bed and wake up? Are these times different on weekends? Under Sleep Schedule, you can create a weekly schedule, allowing for different bedtimes on different days. Note: a consistent bedtime and wake time tends to produce a better night of sleep. Still, excess rigidity may be unrealistic, so pick a schedule that feels reasonable to you.

6. Refine your schedule as needed. If you find that your actual sleep schedule isn’t matching the one you selected, adjust it.
    """
        .trim();
  }

  String _buildStudyAboutLucidDreamsDescription() {
    return """
ABSTRACT:

Lucid dreaming is a unique phenomenon with potential applications for therapeutic interventions. Few studies have investigated the effects of lucidity on an individual’s waking mood, which could have valuable implications for improving psychological wellbeing. The current experiment aims to investigate whether the experience of lucidity enhances positive waking mood, and whether lucidity is associated with dream emotional content and subjective sleep quality. 20 participants were asked to complete lucid dream induction techniques along with an online dream diary for one week, which featured a 19-item lucidity questionnaire, and subjective ratings of sleep quality, dream emotional content, and waking mood. Results indicated that higher lucidity was associated with more positive dream content and elevated positive waking mood the next day, although there was no relationship with sleep quality. The results of the research and suggestions for future investigations, such as the need for longitudinal studies of lucidity and mood, are discussed.
    """
        .trim();
  }
}
