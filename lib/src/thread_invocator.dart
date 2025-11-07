import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

abstract interface class ThreadInvocator {
  Future<Result<T>> execute<T>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<T> Function(InvocationParameters para) function});
  Future<Result<T>> executeResult<T>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Result<T>> Function(InvocationParameters para) function});

  Future<Result<T>> executeFunctionality<T>({required Functionality<T> functionality, required void Function(Oration text) onText});

  Future<Result<T>> executeInteractively<I, T>({InvocationParameters parameters = InvocationParameters.emptry, required void Function(I item) onItem, required FutureOr<T> Function(InvocationParameters para) function});

  Future<Result<T>> executeInteractivelyResult<I, T>({
    InvocationParameters parameters = InvocationParameters.emptry,
    required void Function(I item) onItem,
    required FutureOr<Result<T>> Function(InvocationParameters para) function,
  });

  Stream<T> executeStream<T>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Stream<T>> Function(InvocationParameters para) function});
}
