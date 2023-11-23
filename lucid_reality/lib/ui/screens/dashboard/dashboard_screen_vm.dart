import 'package:flutter_common/viewmodels/viewmodel.dart';

import '../../../di.dart';
import '../navigation.dart';

class DashboardScreenViewModel extends ViewModel {
  final Navigation _navigation = getIt<Navigation>();
}
