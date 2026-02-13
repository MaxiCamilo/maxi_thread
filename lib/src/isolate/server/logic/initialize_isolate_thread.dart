import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

class InitializeIsolateThread with FunctionalityMixin<void> {
  final List<Functionality> initializers;

  const InitializeIsolateThread({required this.initializers});

  static FutureResult<void> runInThread(InvocationParameters parameter) {
    final pack = parameter.firts<InitializeIsolateThread>();
    return pack.runFuncionality();
  }

  @override
  Future<Result<void>> runFuncionality() async {
    for (final initializer in initializers) {
      final result = await initializer.execute();
      if (result.itsFailure) {
        return result;
      }
    }

    return voidResult;
  }
}
