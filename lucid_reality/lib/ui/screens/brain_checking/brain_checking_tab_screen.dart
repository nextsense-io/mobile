import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucid_reality/ui/screens/brain_checking/brain_checking.dart';
import 'package:lucid_reality/ui/screens/brain_checking/brain_checking_main.dart';
import 'package:lucid_reality/ui/screens/brain_checking/brain_checking_vm.dart';
import 'package:stacked/stacked.dart';

import 'brain_checking_results.dart';

class BrainCheckingResultsListScreen extends HookWidget {
  const BrainCheckingResultsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final page = useState(BrainCheckingStages.brainCheckingMain);
    return ViewModelBuilder.reactive(
      viewModelBuilder: () => BrainCheckingViewModule(page),
      onViewModelReady: (viewModel) => viewModel.init(),
      builder: (context, viewModel, child) {
        switch (page.value) {
          case BrainCheckingStages.brainCheckingMain:
            return BrainCheckingMain(viewModel: viewModel);
          case BrainCheckingStages.brainChecking:
            return BrainCheckingScreen(viewModel: viewModel);
          case BrainCheckingStages.brainCheckingResults:
            return BrainCheckingResults(viewModel: viewModel);
        }
      },
    );
  }
}

enum BrainCheckingStages { brainCheckingMain, brainChecking, brainCheckingResults }
