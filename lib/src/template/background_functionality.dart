import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/thread_singleton.dart';

abstract class BackgroundFunctionality<T> with FunctionalityMixin<T> {
  Future<Result<T>> runInternalFuncionalityOnBackground();

  const BackgroundFunctionality();

  @override
  Future<Result<T>> runInternalFuncionality() {
    return threadSystem.backgroundService.executeResult(parameters: InvocationParameters.only(this), function: _runOnThead<T>);
  }

  static FutureResult<T> _runOnThead<T>(InvocationParameters parameters) {
    final functionality = parameters.first<BackgroundFunctionality<T>>();
    return functionality.runInternalFuncionalityOnBackground();
  }
}
