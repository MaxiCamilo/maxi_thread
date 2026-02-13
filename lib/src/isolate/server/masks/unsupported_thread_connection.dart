import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/thread_connection.dart';

class UnsupportedThreadConnection implements ThreadConnection {
  const UnsupportedThreadConnection();

  @override
  void dispose() {}

  @override
  Future<Result<T>> execute<T>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<T> Function(InvocationParameters para) function}) async {
    return NegativeResult.controller(
      code: ErrorCode.implementationFailure,
      message: const FixedOration(message: 'Pointing to a non-existent or discarded connection'),
    );
  }

  @override
  Future<Result<T>> executeResult<T>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<T>> Function(InvocationParameters para) function}) async {
    return NegativeResult.controller(
      code: ErrorCode.implementationFailure,
      message: const FixedOration(message: 'Pointing to a non-existent or discarded connection'),
    );
  }

  @override
  int get identifier => -1;

  @override
  bool get itWasDiscarded => true;

  @override
  String get name => '¿?';

  @override
  Future<dynamic> get onDispose async {}

  @override
  FutureResult<void> requestClosure() async {
    return NegativeResult.controller(
      code: ErrorCode.implementationFailure,
      message: const FixedOration(message: 'Pointing to a non-existent or discarded connection'),
    );
  }
}
