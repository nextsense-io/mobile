import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/domain/survey.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/screens/dashboard/dashboard_screen_vm.dart';
import 'package:nextsense_trial_ui/ui/screens/survey/survey_screen.dart';
import 'package:provider/src/provider.dart';

class DashboardTasksView extends StatelessWidget {
  const DashboardTasksView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dashboardViewModel = context.watch<DashboardScreenViewModel>();
    List<Survey> surveys = dashboardViewModel.getCurrentDaySurveys();

    return SingleChildScrollView(
      physics: ScrollPhysics(),
      child: Container(
          child: ListView.builder(
            scrollDirection: Axis.vertical,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: surveys.length,
            shrinkWrap: true,
            itemBuilder: (BuildContext context, int index) {
              Survey survey = surveys[index];
              return _SurveyItem(survey);
            },
          )),
    );
  }
}

class _SurveyItem extends HookWidget {

  final Navigation _navigation = getIt<Navigation>();

  final Survey survey;

  _SurveyItem(this.survey, {
    Key? key,}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final surveyBackgroundColor = Color(0xFF6DC5D5);
    return Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Opacity(
                opacity: 1.0,
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
                                Text(survey.name,
                                    style: TextStyle(color: Colors.white)),
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
    return Container();
  }

  void _onSurveyClicked(BuildContext context) async {
    // TODO(alex): handle return from survey

    await _navigation.navigateTo(SurveyScreen.id, arguments: survey);
    // Refresh tasks since survey state can be changed
    //context.read<DashboardScreenViewModel>().notifyListeners();
  }

}