import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:rxdart/transformers.dart';

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
  Stream<T> executeStream<T>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Stream<T>> Function(InvocationParameters para) function}) async* {
    final heart = LifeCoordinator.tryGetZoneHeart;

    if (heart == null) {
      yield* await function(parameters);
    } else {
      final controller = heart.joinStreamController(StreamController<T>());

      final subcription = (await function(parameters)).listen(controller.add, onError: controller.addError, onDone: () => controller.close());

      yield* controller.stream.doOnCancel(() => subcription.cancel());
      subcription.cancel();
    }
  }

  @override
  Future<Result<T>> executeInteractively<I, T>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<T> Function(InvocationParameters para) function, required void Function(I item) onItem}) {
    return InteractiveSystem.execute(
      function: () async => ResultValue(content: await function(parameters)),
      onItem: onItem,
    );
  }

  @override
  Future<Result<T>> executeInteractivelyResult<I, T>({
    InvocationParameters parameters = InvocationParameters.emptry,
    required FutureOr<Result<T>> Function(InvocationParameters para) function,
    required void Function(I item) onItem,
  }) {
    return InteractiveSystem.execute(function: () async => await function(parameters), onItem: onItem);
  }
}
