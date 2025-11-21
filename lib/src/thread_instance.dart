import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';

abstract interface class ThreadInstance {
  ThreadInvocator get server;
  ThreadInvocator get background;
  ThreadServiceManager get services;
  ThreadRemoteObjectManager get remoteObjects;


  int get identifier;

  Future<Result<ThreadInvocator>> createThread({required String name});

  static const Symbol isolatedThreadSymbol = #maxiThreadInstance;

  static Result<ThreadInstance> getIsolatedInstance() {
    final isolated = Zone.current[isolatedThreadSymbol];
    if (isolated != null && isolated is ThreadInstance) {
      return ResultValue(content: isolated);
    } else {
      return NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: FixedOration(message: 'No ThreadInstance found in current Zone'),
      );
    }
  }
}
