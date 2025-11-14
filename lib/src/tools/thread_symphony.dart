import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';

class ThreadSymphony with DisposableMixin implements ThreadInvocator {
  final ThreadInstance threadInstance;

  final List<AsyncExecutor> _tasks = [];

  ThreadSymphony({required this.threadInstance});

  @override
  void performObjectDiscard() {
    final clone = _tasks.toList(growable: false);
    _tasks.clear();

    clone.lambda((x) => x.dispose());
  }

  @override
  Future<Result<T>> executeFunctionality<T>({required Functionality<T> functionality, required void Function(Oration text) onText}) {
    resurrectObject();
    return threadInstance.background.executeFunctionality<T>(functionality: functionality, onText: onText);
  }

  Future<Result<List<T>>> executeMultipleFunctions<T>({required List<Functionality<T>> list, void Function(Oration text)? onText}) {
    resurrectObject();

    final pendingTasks = list
        .map(
          (e) => AsyncExecutor.function(
            function: () => threadInstance.background.executeFunctionality(functionality: e, onText: onText ?? (_) {}),
          ),
        )
        .toList();

    final results = <T>[];
    final completer = Completer<Result<List<T>>>();
    bool isCanceled = false;

    final whenHeartbreak = LifeCoordinator.tryGetZoneHeart?.onDispose.whenComplete(() {
      pendingTasks.lambda((x) => x.dispose());
      pendingTasks.clear();
    });

    for (final func in pendingTasks) {
      func.onDispose.whenComplete(() => pendingTasks.remove(func));
      func.waitResult().then((x) {
        if (isCanceled) return;
        pendingTasks.remove(func);
        if (x.itsCorrect && x.content.itsCorrect) {
          results.add(x.content.content);
          if (pendingTasks.isEmpty && !completer.isCompleted) {
            completer.complete(ResultValue(content: results));
            whenHeartbreak?.ignore();
          }
        } else {
          isCanceled = true;
          if (!completer.isCompleted && x.itsFailure) {
            completer.complete(x.cast());
          } else if (!completer.isCompleted && x.content.itsFailure) {
            completer.complete(x.content.cast());
          }

          pendingTasks.lambda((x) => x.dispose());
          pendingTasks.clear();
          whenHeartbreak?.ignore();
        }
      });
    }

    return completer.future;
  }

  @override
  Future<Result<T>> execute<T>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<T> Function(InvocationParameters para) function}) {
    resurrectObject();
    final newTask = AsyncExecutor<T>(
      function: () async {
        if (LifeCoordinator.tryGetZoneHeart?.itWasDiscarded == true) {
          return CancelationResult();
        }

        return await threadInstance.background.execute<T>(function: function, parameters: parameters);
      },
    );
    newTask.connectToHeart();
    _tasks.add(newTask);

    newTask.onDispose.whenComplete(() => _tasks.remove(newTask));

    return newTask.waitResult();
  }

  @override
  Future<Result<T>> executeInteractively<I, T>({InvocationParameters parameters = InvocationParameters.emptry, required void Function(I item) onItem, required FutureOr<T> Function(InvocationParameters para) function}) {
    resurrectObject();
    final newTask = AsyncExecutor<T>(
      function: () async {
        if (LifeCoordinator.tryGetZoneHeart?.itWasDiscarded == true) {
          return CancelationResult();
        }

        return await threadInstance.background.executeInteractively<I, T>(function: function, parameters: parameters, onItem: onItem);
      },
    );
    newTask.connectToHeart();
    _tasks.add(newTask);

    newTask.onDispose.whenComplete(() => _tasks.remove(newTask));

    return newTask.waitResult();
  }

  @override
  Future<Result<T>> executeInteractivelyResult<I, T>({
    InvocationParameters parameters = InvocationParameters.emptry,
    required void Function(I item) onItem,
    required FutureOr<Result<T>> Function(InvocationParameters para) function,
  }) {
    resurrectObject();
    final newTask = AsyncExecutor<T>(
      function: () async {
        if (LifeCoordinator.tryGetZoneHeart?.itWasDiscarded == true) {
          return CancelationResult();
        }

        return await threadInstance.background.executeInteractivelyResult<I, T>(function: function, parameters: parameters, onItem: onItem);
      },
    );
    newTask.connectToHeart();
    _tasks.add(newTask);

    newTask.onDispose.whenComplete(() => _tasks.remove(newTask));

    return newTask.waitResult();
  }

  @override
  Future<Result<T>> executeResult<T>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Result<T>> Function(InvocationParameters para) function}) {
    resurrectObject();
    final newTask = AsyncExecutor<T>(
      function: () async {
        if (LifeCoordinator.tryGetZoneHeart?.itWasDiscarded == true) {
          return CancelationResult();
        }

        return await threadInstance.background.executeResult<T>(function: function, parameters: parameters);
      },
    );
    newTask.connectToHeart();
    _tasks.add(newTask);

    newTask.onDispose.whenComplete(() => _tasks.remove(newTask));

    return newTask.waitResult();
  }

  @override
  Stream<T> executeStream<T>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Stream<T>> Function(InvocationParameters para) function}) {
    // TODO: implement executeStream
    throw UnimplementedError();
  }
}
