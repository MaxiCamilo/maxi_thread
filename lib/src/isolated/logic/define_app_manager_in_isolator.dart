import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

class DefineAppManagerInIsolator with FunctionalityMixin<void> {
  final ApplicationManager appManager;

  const DefineAppManagerInIsolator({required this.appManager});

  @override
  Future<Result<void>> runFuncionality() {
    return ApplicationManager.defineSingleton(appManager);
  }
}
