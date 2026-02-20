import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

/// The `InitializeIsolateThread` class is a functionality that initializes an isolate thread by executing a list of provided initializers. It implements the `FunctionalityMixin` to allow for the execution of its functionality. The class takes a list of `Functionality` objects as initializers, which are executed sequentially when the `runFuncionality` method is called. If any initializer fails during execution, the process is halted and the failure result is returned. If all initializers execute successfully, a void result is returned, indicating that the isolate thread has been initialized successfully. This class serves as a crucial component in setting up the environment for an isolate thread by ensuring that necessary initializations are performed before the thread starts processing tasks. The static method `runInThread` is designed to be executed within the isolate thread, allowing for the initialization process to be triggered with the appropriate parameters when the thread is started.  
class InitializeIsolateThread with FunctionalityMixin<void> {
  final List<Functionality> initializers;

  const InitializeIsolateThread({required this.initializers});

  static FutureResult<void> runInThread(InvocationParameters parameter) {
    final pack = parameter.first<InitializeIsolateThread>();
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
