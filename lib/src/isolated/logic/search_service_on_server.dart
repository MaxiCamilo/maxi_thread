import 'dart:async';
import 'dart:isolate';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/isolated/logic/obtain_send_port.dart';

class SearchSendPortServiceOnServer<T extends Object> with FunctionalityMixin<SendPort> {
  const SearchSendPortServiceOnServer();

  @override
  Future<Result<SendPort>> runFuncionality() async {
    final itsThread = ThreadInstance.getIsolatedInstance();
    if (itsThread.itsFailure) return itsThread.cast();

    final serviceResult = itsThread.content.services.getServiceInvocator<T>();
    if (serviceResult.itsFailure) return serviceResult.cast();

    return serviceResult.content.executeResult(function: (serv, para) => const ObtainSendPort().execute());
  }
}
