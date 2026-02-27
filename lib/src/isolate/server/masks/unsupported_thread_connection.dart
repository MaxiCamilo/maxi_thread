import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/thread_connection.dart';

/// An implementation of the `ThreadConnection` interface that represents an unsupported connection. This class is designed to provide a way to handle cases where a connection is not available or has been discarded, allowing for graceful error handling when attempts are made to execute functions on an unsupported connection. The methods in this class return negative results indicating that the connection is not supported, providing clear feedback to the caller about the unavailability of the connection and preventing attempts to execute functions on an unsupported connection. This implementation is useful for scenarios where a connection may not be available in the current context, allowing for effective error handling and communication about the unsupported nature of the connection while ensuring that operations are not performed on unsupported connections.
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

  @override
  FutureResult<Channel<S, R>> buildChannel<R, S>({
    InvocationParameters parameters = InvocationParameters.empty,
    required FutureOr<Result<void>> Function(Channel<R, S> channel, InvocationParameters para) function,
  }) async {
    return NegativeResult.controller(
      code: ErrorCode.implementationFailure,
      message: const FixedOration(message: 'Pointing to a non-existent or discarded connection'),
    );
  }
}
