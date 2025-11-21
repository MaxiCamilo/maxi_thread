import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';

class IsolatedServiceClientWittEntity<E> implements ThreadServiceManager, ThreadServiceInvocator<E> {
  final E entity;
  final ThreadServiceManager services;

  @override
  bool isCompatible(Type type) => type == E;

  @override
  Type get serviceType => entity.runtimeType;

  const IsolatedServiceClientWittEntity({required this.entity, required this.services});

  @override
  Future<Result<bool>> hasService(Type type) async {
    if (isCompatible(type)) {
      return ResultValue(content: true);
    }

    return services.hasService(type);
  }

  @override
  Future<Result<ThreadServiceInvocator<T>>> createServiceThread<T extends Object>({required T item, bool skipIfAlreadyMounted = true, String? name}) async {
    if (item.runtimeType == E) {
      if (skipIfAlreadyMounted) {
        return asResultValue().cast<ThreadServiceInvocator<T>>();
      } else {
        return NegativeResult.controller(
          code: ErrorCode.implementationFailure,
          message: FlexibleOration(message: 'Service %1 has already been mounted', textParts: [T]),
        );
      }
    }

    return services.createServiceThread<T>(item: item, skipIfAlreadyMounted: skipIfAlreadyMounted, name: name);
  }

  @override
  Future<Result<R>> execute<R>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<R> Function(E serv, InvocationParameters para) function}) async {
    try {
      final result = await function(entity, parameters);
      return ResultValue<R>(content: result);
    } catch (ex, st) {
      return ExceptionResult<R>(exception: ex, stackTrace: st);
    }
  }

  @override
  Future<Result<R>> executeResult<R>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Result<R>> Function(E serv, InvocationParameters para) function}) {
    return function(entity, parameters).asFutureResult();
  }

  @override
  Result<ThreadServiceInvocator<T>> getServiceInvocator<T extends Object>() {
    if (T == E) {
      return asResultValue().cast<ThreadServiceInvocator<T>>();
    }

    return services.getServiceInvocator<T>();
  }

  @override
  Stream<R> executeStream<R>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Result<Stream<R>>> Function(E serv, InvocationParameters para) function}) async* {
    final stream = await function(entity, parameters);
    if (stream.itsFailure) throw stream;

    yield* stream.content;
  }
}
