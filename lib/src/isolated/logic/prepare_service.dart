import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/isolated/clients/isolated_thread_client.dart';

class PrepareService<T extends Object> with FunctionalityMixin<void> {
  final T service;

  const PrepareService({required this.service});

  @override
  Future<Result<void>> runFuncionality() async {
    final itsClientThread = ThreadInstance.getIsolatedInstance().cast<IsolatedThreadClient>();
    if (itsClientThread.itsFailure) return itsClientThread.cast();

    itsClientThread.content.changeToEntityThread<T>(service);

    if (service is Initializable) {
      final initResult = (service as Initializable).initialize();
      if (initResult.itsFailure) return initResult.cast();
    }

    if (service is AsynchronouslyInitialized) {
      final initResult = await (service as AsynchronouslyInitialized).initialize();
      if (initResult.itsFailure) return initResult.cast();
    }

    return voidResult;
  }
}
