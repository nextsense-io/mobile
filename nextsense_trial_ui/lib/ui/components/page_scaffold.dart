import 'package:flutter/material.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:nextsense_trial_ui/ui/components/nextsense_app_bar.dart';
import 'package:nextsense_trial_ui/ui/components/page_container.dart';
import 'package:flutter_common/viewmodels/viewmodel.dart';

class PageScaffold extends StatelessWidget {

  final Widget child;
  final ViewModel? viewModel;
  final bool padBottom;
  final bool showBackground;
  final bool showBackButton;
  final bool showProfileButton;
  final bool showCancelButton;
  final Color backgroundColor;
  final Widget? floatingActionButton;
  final VoidCallback? backButtonCallback;

  const PageScaffold({super.key, required this.child, this.viewModel, this.showBackground = true,
    this.showBackButton = true, this.showProfileButton = true, this.floatingActionButton,
    this.showCancelButton = false, this.backgroundColor = Colors.transparent,
    this.padBottom = true, this.backButtonCallback});

  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
      if (showBackground) Image(
          image: const Svg("packages/nextsense_trial_ui/assets/images/background.svg"),
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          fit: BoxFit.cover,
          color: Colors.white.withOpacity(1.0),
          colorBlendMode: BlendMode.dstOver),
      Scaffold(
          backgroundColor: backgroundColor,
          appBar: NextSenseAppBar(
              viewModel: viewModel, showBackButton: showBackButton,
              showProfileButton: showProfileButton, backButtonCallback: backButtonCallback,
              showCancelButton: showCancelButton),
          body: PageContainer(padBottom: padBottom, child: child),
          floatingActionButton: floatingActionButton,
      ),
    ]);
  }
}