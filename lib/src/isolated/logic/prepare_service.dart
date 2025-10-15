import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';

class PrepareService<T> with FunctionalityMixin<void> {
  final T service;

  const PrepareService({required this.service});

  @override
  Future<Result<void>> runFuncionality() async {
    ThreadEntity.defineEntity(service);

    if (service is Initializable) {
      final initResult = (service as Initializable).initialize();
      if (initResult.itsFailure) return initResult;
    }

    if (service is AsynchronouslyInitialized) {
      final initResult = await (service as AsynchronouslyInitialized).initialize();
      if (initResult.itsFailure) return initResult;
    }

    return voidResult;
  }
}
