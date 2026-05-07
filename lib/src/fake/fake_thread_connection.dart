import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/fake/fake_thread_manager.dart';

class FakeThreadConnection with DisposableMixin implements ThreadConnection {
  @override
  final int identifier;

  @override
  final String name;

  final FakeThreadManager manager;

  FakeThreadConnection({required this.identifier, required this.name, required this.manager});

  @override
  FutureResult<Channel<S, R>> buildChannel<R, S>({
    InvocationParameters parameters = InvocationParameters.empty,
    required FutureOr<Result<dynamic>> Function(Channel<R, S> channel, InvocationParameters para) function,
  }) async {
    final master = MasterChannel<S, R>(closeWhenNoSlaves: true);
    final childResult = master.buildConnector();
    if (childResult.itsFailure) {
      return childResult.cast();
    }

    final child = childResult.content;

    AsyncExecutor(
      function: () => function(child, parameters),
      connectToZone: true,
    ).waitResult(zoneValues: {ThreadManager.kThreadManagerZone: manager, ThreadConnection.kThreadConnectionZone: this}).whenComplete(() => master.dispose());

    return master.asResultValue();
  }

  @override
  Future<Result<T>> execute<T>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<T> Function(InvocationParameters para) function}) {
    return AsyncExecutor<T>(
      function: () async => ResultValue(content: await function(parameters)),
      connectToZone: true,
    ).waitResult(zoneValues: {ThreadManager.kThreadManagerZone: manager, ThreadConnection.kThreadConnectionZone: this});
  }

  @override
  Future<Result<T>> executeResult<T>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<T>> Function(InvocationParameters para) function}) {
    return AsyncExecutor<T>(function: () => function(parameters), connectToZone: true).waitResult(zoneValues: {ThreadManager.kThreadManagerZone: manager, ThreadConnection.kThreadConnectionZone: this});
  }

  @override
  FutureResult<void> requestClosure() async {
    dispose();
    return voidResult;
  }

  @override
  void performObjectDiscard() {}
}
