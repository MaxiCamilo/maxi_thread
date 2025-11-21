import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

abstract interface class ThreadServiceInvocator<T> {
  Type get serviceType;
  bool isCompatible(Type type);

  Future<Result<R>> execute<R>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<R> Function(T serv, InvocationParameters para) function});
  Future<Result<R>> executeResult<R>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Result<R>> Function(T serv, InvocationParameters para) function});
  Stream<R> executeStream<R>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Result<Stream<R>>> Function(T serv, InvocationParameters para) function});
}
