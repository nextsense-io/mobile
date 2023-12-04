import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucid_reality/ui/screens/pvt/psychomotor_vigilance_test_main_screen.dart';
import 'package:lucid_reality/ui/screens/pvt/psychomotor_vigilance_test_results_screen.dart';
import 'package:lucid_reality/ui/screens/pvt/psychomotor_vigilance_test_screen.dart';
import 'package:lucid_reality/ui/screens/pvt/psychomotor_vigilance_test_vm.dart';
import 'package:stacked/stacked.dart';

class PsychomotorVigilanceTestListScreen extends HookWidget {
  const PsychomotorVigilanceTestListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final page = useState(PsychomotorVigilanceTestStages.pvtMain);
    return ViewModelBuilder.reactive(
      viewModelBuilder: () => PsychomotorVigilanceTestViewModule(page),
      onViewModelReady: (viewModel) => viewModel.init(),
      builder: (context, viewModel, child) {
        switch (page.value) {
          case PsychomotorVigilanceTestStages.pvtMain:
            return PsychomotorVigilanceTestMainScreen(viewModel: viewModel);
          case PsychomotorVigilanceTestStages.pvt:
            return PsychomotorVigilanceTestScreen(viewModel: viewModel);
          case PsychomotorVigilanceTestStages.pvtResults:
            return PsychomotorVigilanceTestResultsScreen(viewModel: viewModel);
        }
      },
    );
  }
}

enum PsychomotorVigilanceTestStages { pvtMain, pvt, pvtResults }
