import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/isolate/isolated_thread.dart';
import 'package:maxi_thread/src/thread_connection.dart';
import 'package:maxi_thread/src/thread_manager.dart';
import 'package:maxi_thread/src/thread_singleton.dart';

/// A class that implements the `ThreadConnection` interface and represents a connection to the current thread
class SelfThreadConnection implements ThreadConnection {
  final IsolatedThread isolatedThread;

  const SelfThreadConnection(this.isolatedThread);

  @override
  int get identifier => isolatedThread.identifier;

  @override
  String get name => isolatedThread.name;

  @override
  Future<Result<T>> execute<T>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<T> Function(InvocationParameters para) function}) {
    return AsyncExecutor<T>.function(function: () => function(parameters)).waitResult(zoneValues: {ThreadManager.kThreadManagerZone: threadSystem, ThreadConnection.kThreadConnectionZone: this});
  }

  @override
  Future<Result<T>> executeResult<T>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<T>> Function(InvocationParameters para) function}) {
    return AsyncExecutor<T>(function: () => function(parameters)).waitResult(zoneValues: {ThreadManager.kThreadManagerZone: threadSystem, ThreadConnection.kThreadConnectionZone: this});
  }

  @override
  bool get itWasDiscarded => isolatedThread.itWasDiscarded;

  @override
  Future<dynamic> get onDispose => isolatedThread.onDispose;

  @override
  FutureResult<void> requestClosure() async {
    isolatedThread.dispose();
    return voidResult;
  }

  @override
  void dispose() {
    isolatedThread.dispose();
  }

  @override
  FutureResult<Channel<S, R>> buildChannel<R, S>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<Channel<R, S>>> Function(InvocationParameters para) function}) async {
    final newChannelResult = await function(parameters);
    return newChannelResult.asResultValue();
  }
}
