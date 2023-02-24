import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nextsense_trial_ui/di.dart';
import 'package:nextsense_trial_ui/ui/components/alert.dart';
import 'package:nextsense_trial_ui/ui/components/header_text.dart';
import 'package:nextsense_trial_ui/ui/components/medium_text.dart';
import 'package:nextsense_trial_ui/ui/components/page_scaffold.dart';
import 'package:nextsense_trial_ui/ui/components/session_pop_scope.dart';
import 'package:nextsense_trial_ui/ui/components/simple_button.dart';
import 'package:nextsense_trial_ui/ui/navigation.dart';
import 'package:nextsense_trial_ui/ui/nextsense_colors.dart';
import 'package:nextsense_trial_ui/ui/screens/auth/enter_email_screen_vm.dart';
import 'package:stacked/stacked.dart';

class EnterEmailScreen extends HookWidget {
  static const String id = 'enter_email_screen';

  final _navigation = getIt<Navigation>();

  Widget _buildBody(BuildContext context, EnterEmailScreenViewModel viewModel) {
    if (viewModel.hasError) {
      Future.delayed(Duration.zero, () {
        showDialog(
            context: context,
            builder: (_) => SimpleAlertDialog(
                title: 'Error',
                content: viewModel.modelError,
                onPressed: () => viewModel.clearErrors()));
      });
    }
    return Container(
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            Padding(
                padding: EdgeInsets.all(10.0),
                child: MediumText(
                    text:
                    'Please enter your email address to continue.')),
            Padding(
              padding: EdgeInsets.all(10.0),
              child: TextFormField(
                cursorColor: TextSelectionTheme.of(context).cursorColor,
                initialValue: '',
                maxLength: 40,
                decoration: InputDecoration(
                  labelText: 'Enter your email',
                  labelStyle: TextStyle(
                    color: NextSenseColors.purple,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6200EE)),
                  ),
                ),
                onChanged: (email) {
                  viewModel.email = email;
                },
              ),
            ),
            Padding(
                padding: EdgeInsets.all(10.0),
                child: SimpleButton(
                  text: MediumText(text: 'Submit', color: NextSenseColors.darkBlue),
                  onTap: viewModel.isBusy ? () => {} :
                      () async => _onSubmitButton(context, viewModel),
                )),
            Visibility(
              visible: viewModel.isBusy,
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          ]),
        ));
  }

  Future _onSubmitButton(
      BuildContext context, EnterEmailScreenViewModel viewModel) async {
    viewModel.setEmailInAuthManager();
    await Future.delayed(Duration(seconds: 0));
    _navigation.pop();
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<EnterEmailScreenViewModel>.reactive(
        viewModelBuilder: () => EnterEmailScreenViewModel(),
        onModelReady: (viewModel) => viewModel.init(),
        builder: (context, viewModel, child) => SessionPopScope(
            child: PageScaffold(
                showBackButton: false,
                showProfileButton: false,
                child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Spacer(),
                  HeaderText(text: 'Enter your Email'),
                  SizedBox(height: 20),
                  _buildBody(context, viewModel),
                  Spacer()
                ]))));
  }
}
