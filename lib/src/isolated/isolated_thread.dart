import 'dart:async';
import 'dart:isolate';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/isolated/isolate_stream_manager.dart';

abstract interface class IsolatedThread {
  IsolateStreamManager get streamManager;

  Future<Result<ThreadInvocator>> getInvocatorByID({required int identifier});

  Future<Result<void>> closeThread();
  Future<Result<SendPort>> getNewSendPortFromThread();
}
