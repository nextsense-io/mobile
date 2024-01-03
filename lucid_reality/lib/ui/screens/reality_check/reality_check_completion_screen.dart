import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:lucid_reality/ui/components/app_body.dart';
import 'package:lucid_reality/utils/utils.dart';
import 'package:stacked/stacked.dart';

import 'reality_check_base_vm.dart';

class RealityCheckCompletionScreen extends HookWidget {
  static const String id = 'reality_check_completion_screen';

  const RealityCheckCompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = useRef(RealityCheckBaseViewModel());
    useEffect(() {
      Future.delayed(
        const Duration(seconds: 5),
        () {
          viewModel.value.goBack();
        },
      );
      return null;
    }, []);
    return ViewModelBuilder.reactive(
      viewModelBuilder: () => viewModel.value,
      onViewModelReady: (viewModel) => viewModel.init(),
      builder: (context, viewModel, child) {
        return SafeArea(
          child: Scaffold(
            body: AppBody(
                child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image(image: Svg(imageBasePath.plus('ic_rounded_right.svg'))),
                  const SizedBox(height: 13),
                  Text(
                    'All Done!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  )
                ],
              ),
            )),
          ),
        );
      },
    );
  }
}
