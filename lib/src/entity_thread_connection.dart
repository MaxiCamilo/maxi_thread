import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

/// Signature that allows executing functions dedicated to a specific entity, enabling more direct and efficient communication with threads dedicated to specific entities, facilitating the execution of functions related to a particular entity and improving communication efficiency between threads in applications that require specific entity management.
abstract interface class EntityThreadConnection<T> {
  Future<Result<R>> execute<R>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<R> Function(T serv, InvocationParameters para) function});
  Future<Result<R>> executeResult<R>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<R>> Function(T serv, InvocationParameters para) function});
  FutureResult<Channel<S, R>> buildChannel<R, S>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<Channel<R, S>>> Function(T serv, InvocationParameters para) function});
}
