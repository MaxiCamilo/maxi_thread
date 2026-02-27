import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

/// Signature that defines the operations for communication between threads, allowing the execution of functions on a specific thread and facilitating communication between threads in applications that require concurrent operations and resource management across multiple threads.
abstract interface class ThreadConnection implements Disposable {
  static const kThreadConnectionZone = #maxiThreadConnection;

  int get identifier;
  String get name;
  Future<Result<T>> execute<T>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<T> Function(InvocationParameters para) function});
  Future<Result<T>> executeResult<T>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<T>> Function(InvocationParameters para) function});
  FutureResult<Channel<S, R>> buildChannel<R, S>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<void>> Function(Channel<R, S> channel, InvocationParameters para) function});
  FutureResult<void> requestClosure();

  static ThreadConnection get threadZone => Zone.current[kThreadConnectionZone]! as ThreadConnection;
}
