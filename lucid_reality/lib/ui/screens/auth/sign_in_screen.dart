import 'package:flutter/material.dart';
import 'package:flutter_common/managers/auth/auth_method.dart';
import 'package:flutter_common/managers/auth/authentication_result.dart';
import 'package:flutter_common/ui/components/alert.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:lucid_reality/ui/screens/auth/sign_in_screeen_vm.dart';
import 'package:lucid_reality/utils/text_theme.dart';
import 'package:lucid_reality/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:stacked/stacked.dart';

class SignInScreen extends HookWidget {
  static const String id = 'sign_in_screen';

  SignInScreen({super.key});

  bool authenticating = false;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder.reactive(
      viewModelBuilder: () => SignInViewModel(),
      onViewModelReady: (viewModel) => viewModel.init(),
      builder: (context, viewModel, child) {
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: ExactAssetImage(imageBasePath.plus("splash_screen.png")),
                    fit: BoxFit.fill)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(
                  flex: 8,
                ),
                AbsorbPointer(
                  absorbing: authenticating,
                  child: SignInButton(
                    Buttons.Google,
                    onPressed: () {
                      if (!authenticating) {
                        _signIn(context, AuthMethod.google_auth);
                      }
                    },
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                Text("LUCID REALITY",
                    style: Theme.of(context).textTheme.titleMediumWithFontWeight500),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  "Enhancing human potential",
                  style: Theme.of(context).textTheme.bodyMediumWithFontWeight300,
                ),
                const Spacer(
                  flex: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future _signIn(BuildContext context, AuthMethod authMethod) async {
    final viewModel = context.read<SignInViewModel>();
    authenticating = true;
    AuthenticationResult authResult = await viewModel.signIn(authMethod);
    print('authResult==>$authResult');
    if (authResult != AuthenticationResult.success) {
      authenticating = false;
      String dialogTitle, dialogContent;
      switch (authResult) {
        case AuthenticationResult.user_fetch_failed:
        case AuthenticationResult.invalid_user_setup:
        case AuthenticationResult.invalid_username_or_password:
          dialogTitle = 'Invalid email or password';
          dialogContent = 'The email is incorrect or you entered a wrong password';
          break;
        case AuthenticationResult.connection_error:
          dialogTitle = 'Connection error';
          dialogContent = 'An internet connection is needed to validate your password.';
          break;
        default:
          dialogTitle = 'Error';
          dialogContent = 'Error occurred. Please contact support';
          break;
      }
      await showDialog(
          context: context,
          builder: (_) => SimpleAlertDialog(title: dialogTitle, content: dialogContent));
      return;
    }
    viewModel.redirectToDashboard();
    authenticating = false;
  }
}
