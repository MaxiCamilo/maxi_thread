import 'dart:async';
import 'dart:isolate';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/entity_thread_connection.dart';
import 'package:maxi_thread/src/isolate/client/isolated_thread_client.dart';
import 'package:maxi_thread/src/isolate/server/isolated_thread_server.dart';
import 'package:maxi_thread/src/isolate/server/masks/entity_isolate_thread_connection.dart';
import 'package:maxi_thread/src/thread_connection.dart';
import 'package:maxi_thread/src/thread_singleton.dart';
import 'package:meta/meta.dart';

/// Represents a connection to an entity thread in an isolated environment, allowing communication and interaction with the entity managed by the thread. This class serves as a mask connection that abstracts the underlying communication details and provides a convenient interface for executing functions on the entity thread.
/// The `EntityThreadMaskConnection` class implements the `EntityThreadConnection` interface and utilizes an underlying `EntityIsolateThreadConnection` to perform the actual communication with the entity thread.
class EntityThreadMaskConnection<T> with AsynchronouslyInitializedMixin implements EntityThreadConnection<T> {
  final ThreadConnection serverConnection;
  final IsolatedThreadClient clientConnection;

  late EntityIsolateThreadConnection<T> _isolateConnection;

  EntityThreadMaskConnection({required this.serverConnection, required this.clientConnection});

  @override
  @protected
  Future<Result<void>> performInitialize() async {
    final sendPortResult = await serverConnection.executeResult(function: _getEntitySendPort<T>);
    if (sendPortResult.itsFailure) {
      return sendPortResult.cast();
    }

    final connectionResult = await clientConnection.connectSendPort(sendPortResult.content);
    if (connectionResult.itsFailure) {
      return connectionResult.cast();
    }
    _isolateConnection = EntityIsolateThreadConnection<T>(connectionResult.content);
    return voidResult;
  }

  static FutureResult<SendPort> _getEntitySendPort<T>(InvocationParameters parameters) async {
    final serverResult = threadSystem.dynamicCastResult<IsolatedThreadServer>(errorMessage: const FixedOration(message: 'The thread connection is not a server, which is required to obtain the entity send port'));
    if (serverResult.itsFailure) {
      return serverResult.cast();
    }

    final server = serverResult.content;
    return server.obtainEntitySendPort<T>();
  }

  @override
  Future<Result<R>> execute<R>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<R> Function(T serv, InvocationParameters para) function}) async {
    return initialize().onCorrectFuture((_) => _isolateConnection.execute(function: function, parameters: parameters));
  }

  @override
  Future<Result<R>> executeResult<R>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<R>> Function(T serv, InvocationParameters para) function}) {
    return initialize().onCorrectFuture((_) => _isolateConnection.executeResult(function: function, parameters: parameters));
  }

  @override
  FutureResult<Channel<S, R>> buildChannel<R, S>({
    InvocationParameters parameters = InvocationParameters.empty,
    required FutureOr<Result<dynamic>> Function(T serv, Channel<R, S> channel, InvocationParameters para) function,
  }) {
    return initialize().onCorrectFuture((_) => _isolateConnection.buildChannel(parameters: parameters, function: function));
  }
}
