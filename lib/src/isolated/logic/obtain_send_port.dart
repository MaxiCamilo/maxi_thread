import 'dart:async';
import 'dart:isolate';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';

class ObtainSendPort with FunctionalityMixin<SendPort> {
  const ObtainSendPort();

  @override
  FutureOr<Result<SendPort>> runFuncionality() async {
    final itsIsolate = ThreadInstance.getIsolatedInstance().cast<IsolatedThread>();
    if (itsIsolate.itsFailure) return itsIsolate.cast();

    return itsIsolate.content.getNewSendPortFromThread();
  }
}
