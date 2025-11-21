import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';

class MainThreadInstance implements ThreadInvocator {
  const MainThreadInstance();

  @override
  Future<Result<T>> execute<T>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<T> Function(InvocationParameters para) function}) {
    final instance = AsyncExecutor.function(function: () => function(parameters));
    instance.connectToHeart();
    return instance.waitResult();
  }

  @override
  Future<Result<T>> executeResult<T>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Result<T>> Function(InvocationParameters para) function}) async {
    final instance = AsyncExecutor.function(function: () => function(parameters));
    instance.connectToHeart();
    final result = await instance.waitResult();
    if (result.itsCorrect) {
      return result.content;
    } else {
      return result.cast();
    }
  }

  @override
  Future<Result<T>> executeFunctionality<T>({required Functionality<T> functionality}) => functionality.execute();

  @override
  Stream<T> executeStream<T>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Result<Stream<T>>> Function(InvocationParameters para) function}) async* {
    final stream = await function(parameters);
    if (stream.itsFailure) throw stream.logIfFails(errorName: 'MainThreadInstance');

    yield* stream.content;
  }
}
