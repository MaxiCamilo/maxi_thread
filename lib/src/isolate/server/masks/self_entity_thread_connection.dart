import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/entity_thread_connection.dart';
import 'package:maxi_thread/src/thread_connection.dart';
import 'package:maxi_thread/src/thread_manager.dart';
import 'package:maxi_thread/src/thread_singleton.dart';

/// An implementation of the `EntityThreadConnection` interface that allows for executing functions on a local instance of a service
class SelfEntityThreadConnection<T> implements EntityThreadConnection<T> {
  final T instance;

  const SelfEntityThreadConnection({required this.instance});

  @override
  Future<Result<R>> execute<R>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<R> Function(T serv, InvocationParameters para) function}) {
    return AsyncExecutor<R>.function(function: () => function(instance, parameters)).waitResult(zoneValues: {ThreadManager.kThreadManagerZone: threadSystem, ThreadConnection.kThreadConnectionZone: this});
  }

  @override
  Future<Result<R>> executeResult<R>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<R>> Function(T serv, InvocationParameters para) function}) {
    return AsyncExecutor<R>(function: () => function(instance, parameters)).waitResult(zoneValues: {ThreadManager.kThreadManagerZone: threadSystem, ThreadConnection.kThreadConnectionZone: this});
  }

  @override
  FutureResult<Channel<S, R>> buildChannel<R, S>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<Channel<R, S>>> Function(T serv, InvocationParameters para) function}) {
    return executeResult(
      function: (_, _) async {
        final channelResult = await function(instance, parameters);
        if (channelResult.itsFailure) {
          return channelResult.cast();
        }

        if (channelResult.content is MasterChannel<R, S>) {
          return (channelResult.content as MasterChannel<R, S>).buildConnector();
        } else {
          return MasterChannel.mirror(origin: channelResult.content).asResultValue();
        }
      },
    );
  }
}
