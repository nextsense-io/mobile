import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/survey/scheduled_survey.dart';
import 'package:nextsense_trial_ui/domain/survey/survey.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_screen_vm.dart';
import 'package:nextsense_trial_ui/ui/screens/survey/survey_screen.dart';
import 'package:provider/src/provider.dart';

class DashboardTasksView extends StatelessWidget {
  const DashboardTasksView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dashboardViewModel = context.watch<DashboardScreenViewModel>();
    List<ScheduledSurvey> scheduledSurveys =
        dashboardViewModel.getCurrentDayScheduledSurveys();

    final SurveyStats? surveyStats = dashboardViewModel.surveyStats;
    return SingleChildScrollView(
      physics: ScrollPhysics(),
      child: Column(
        children: [
          if (surveyStats != null)
            Card(
            color: Colors.deepPurple,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Completed ${surveyStats.completed}/${surveyStats.total} Surveys",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          Container(
              child: scheduledSurveys.isNotEmpty ? ListView.builder(
                scrollDirection: Axis.vertical,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: scheduledSurveys.length,
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int index) {
                  ScheduledSurvey survey = scheduledSurveys[index];
                  return _SurveyItem(survey);
                },
              ) : _emptyTasksPlaceholder()),
        ],
      ),
    );
  }

  Widget _emptyTasksPlaceholder() {
      return Container(
          padding: EdgeInsets.all(30.0),
          child: Column(
            children: [
              Icon(Icons.task, size: 50, color: Colors.grey,),
              SizedBox(height: 20,),
              Text("There are no tasks for selected day",
                  textAlign: TextAlign.center, style:
                  TextStyle(fontSize: 30.0, color: Colors.grey)),
            ],
     ));
  }
}

class _SurveyItem extends HookWidget {

  final Navigation _navigation = getIt<Navigation>();

  final ScheduledSurvey scheduledSurvey;

  _SurveyItem(this.scheduledSurvey, {
    Key? key,}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var surveyBackgroundColor = Color(0xFF6DC5D5);
    // TODO(alex): introduce survey type?
    if (scheduledSurvey.survey.id.contains("phq")) {
      surveyBackgroundColor = Color(0xFF984DF1);
    } else if (scheduledSurvey.survey.id.contains("gad")) {
      surveyBackgroundColor = Color(0xFFE6AEA0);
    }

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Opacity(
                opacity: scheduledSurvey.isCompleted
                        || scheduledSurvey.isSkipped ? 0.6 : 1.0,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: InkWell(
                    onTap: () {
                      _onSurveyClicked(context);
                    },
                    child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: new BoxDecoration(
                            color: surveyBackgroundColor,
                            borderRadius: new BorderRadius.all(
                                const Radius.circular(5.0))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(scheduledSurvey.survey.name,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(
                                  height: 8,
                                ),
                                Text("Please complete survey",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18)),
                                SizedBox(
                                  height: 8,
                                ),
                              ],
                            ),
                            _surveyState()
                          ],
                        )),
                  ),
                ),
              ),
            ),
          ],
        ));
  }

  Widget _surveyState() {
    switch(scheduledSurvey.state) {
      case SurveyState.skipped:
        return Column(
          children: [
            Icon(Icons.cancel, color: Colors.white),
            Text("Skipped", style: TextStyle(color: Colors.white),),
          ],
        );
      case SurveyState.completed:
        return Icon(Icons.check_circle, color: Colors.white);
      default: break;
    }
    return Container();
  }

  void _onSurveyClicked(BuildContext context) async {
    if (scheduledSurvey.isCompleted) {
      showDialog(
        context: context,
        builder: (_) => SimpleAlertDialog(
            title: 'Warning',
            content: 'Survey is already completed'),
      );
      return;
    }

    if (scheduledSurvey.isSkipped) {
      showDialog(
        context: context,
        builder: (_) => SimpleAlertDialog(
            title: 'Warning',
            content: 'Cannot start survey cause its already skipped'),
      );
      return;
    }

    bool completed = await _navigation.navigateTo(SurveyScreen.id,
        arguments: scheduledSurvey);

    if (completed) {
      showDialog(
        context: context,
        builder: (_) => SimpleAlertDialog(
            title: 'Success',
            content: 'Survey successfully completed!'),
      );
    }
    // Refresh tasks since survey state can be changed
    context.read<DashboardScreenViewModel>().notifyListeners();
  }

}