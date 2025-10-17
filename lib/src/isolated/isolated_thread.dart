import 'dart:isolate';

import 'package:maxi_framework/maxi_framework.dart';

abstract interface class IsolatedThread {
  Future<Result<void>> closeThread();
  Future<Result<SendPort>> getNewSendPortFromThread();
}
