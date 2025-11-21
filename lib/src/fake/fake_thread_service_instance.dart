import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';

class FakeThreadServiceInstance<T> implements ThreadServiceInvocator<T> {
  final T entity;

  const FakeThreadServiceInstance._({required this.entity});

  static Future<Result<FakeThreadServiceInstance<T>>> instanced<T>({required T item}) async {
    final newIntance = FakeThreadServiceInstance<T>._(entity: item);

    if (item is Initializable) {
      final initResult = (item as Initializable).initialize();
      if (initResult.itsFailure) return initResult.cast();
    }

    if (item is AsynchronouslyInitialized) {
      final initResult = await (item as AsynchronouslyInitialized).initialize();
      if (initResult.itsFailure) return initResult.cast();
    }

    return newIntance.asResultValue();
  }

  @override
  Type get serviceType => T;

  @override
  bool isCompatible(Type type) => type == T;

  @override
  Future<Result<R>> execute<R>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<R> Function(T serv, InvocationParameters para) function}) async {
    return ResultValue(content: await function(entity, parameters));
  }

  @override
  Future<Result<R>> executeResult<R>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Result<R>> Function(T serv, InvocationParameters para) function}) async {
    return await function(entity, parameters);
  }

  @override
  Stream<R> executeStream<R>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Result<Stream<R>>> Function(T serv, InvocationParameters para) function}) async* {
    final stream = await function(entity, parameters);
    if (stream.itsFailure) throw stream;

    yield* stream.content;
  }
}
