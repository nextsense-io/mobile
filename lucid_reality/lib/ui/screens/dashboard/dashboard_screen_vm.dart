import 'package:flutter_common/viewmodels/viewmodel.dart';

import 'package:lucid_reality/di.dart';
import 'package:lucid_reality/ui/screens/navigation.dart';

class DashboardScreenViewModel extends ViewModel {
  final Navigation _navigation = getIt<Navigation>();
}
