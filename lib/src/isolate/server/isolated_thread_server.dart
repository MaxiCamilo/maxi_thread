import 'dart:isolate';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/entity_thread_connection.dart';
import 'package:maxi_thread/src/isolate/client/isolated_thread_client.dart';
import 'package:maxi_thread/src/isolate/isolated_thread.dart';
import 'package:maxi_thread/src/isolate/server/logic/initialize_isolate_thread.dart';
import 'package:maxi_thread/src/isolate/server/logic/spawn_entity_isolate.dart';
import 'package:maxi_thread/src/isolate/server/logic/spawn_isolate.dart';
import 'package:maxi_thread/src/isolate/server/masks/self_thread_connection.dart';
import 'package:maxi_thread/src/isolate/server/masks/unsupported_entity_thread_connection.dart';
import 'package:maxi_thread/src/thread_connection.dart';
import 'package:maxi_thread/src/thread_singleton.dart';

/// Represents the server-side implementation of an isolated thread, responsible for managing and coordinating communication with multiple isolate threads. This class extends the `IsolatedThread` class and provides functionality for creating new isolate threads, managing entity thread connections, and facilitating communication between the main thread and the isolate threads. The `IsolatedThreadServer` class maintains a collection of external connections to isolate threads, pending connections for initialization, and entity connections for managing specific entities within the isolate threads. It provides methods for creating new threads, creating entity threads, obtaining connections based on identifiers, and obtaining send ports for communication with the isolate threads. This implementation allows for effective management of isolate threads and facilitates communication between the main thread and the isolate threads in a multi-threaded application. The class also ensures proper handling of thread lifecycle events, such as disposal and cleanup of resources, to prevent memory leaks and ensure efficient resource management in a multi-threaded environment. Overall, the `IsolatedThreadServer` class serves as a crucial component in managing the lifecycle of isolate threads and facilitating communication between the main thread and the isolate threads in a multi-threaded application, allowing for concurrent processing and efficient resource management in an isolated environment.
class IsolatedThreadServer extends IsolatedThread {
  @override
  int get identifier => 0;

  @override
  String get name => 'Isolated Thread Server';

  final _spawnMutex = Mutex();
  final _entityMutex = Mutex();

  int _lastIdentifier = 1;

  @override
  ThreadConnection get serverConnection => SelfThreadConnection(this);

  @override
  FutureResult<ThreadConnection> createThread({required String name, List<Functionality> initializers = const []}) async {
    Functionality<ApplicationManager>? hasReplicant;

    /// If the compiled application requires replicating its general operator across threads, we define them in the created threads
    if (appManager is IsolatedReplicableApplicationManager) {
      final replicantResult = await (appManager as IsolatedReplicableApplicationManager).cloneToIsolate();
      if (replicantResult.itsFailure) return replicantResult.cast();
      hasReplicant = replicantResult.content;
    }

    final spawnResult = await _spawnMutex.execute(() {
      final init = SpawnIsolate(identifier: _lastIdentifier, name: name);
      _lastIdentifier += 1;
      return init.execute();
    });

    if (spawnResult.itsFailure) {
      return spawnResult.cast();
    }

    final connection = spawnResult.content;

    if (hasReplicant != null) {
      final replicantResult = await connection.executeResult(parameters: InvocationParameters.only(hasReplicant), function: _replicantAppManager);
      if (replicantResult.itsFailure) {
        await connection.requestClosure().logIfFails(errorName: 'IsolatedThreadServer -> CreateThread: Failed to close thread after replicant initialization failure');

        return replicantResult.cast();
      }
    }

    final initializationResult = await connection.executeResult(
      parameters: InvocationParameters.only(InitializeIsolateThread(initializers: initializers)),
      function: InitializeIsolateThread.runInThread,
    );
    if (initializationResult.itsFailure) {
      await connection.requestClosure().logIfFails(errorName: 'IsolatedThreadServer -> CreateThread: Failed to close thread after initialization failure');

      return initializationResult.cast();
    }

    externalConnections.add(connection);
    connection.onDispose.whenComplete(() => externalConnections.remove(connection));
    return connection.asResultValue();
  }

  static FutureResult<void> _replicantAppManager(InvocationParameters parameters) async {
    final replicant = parameters.first<Functionality<ApplicationManager>>();
    final appManagerResult = await replicant.execute();
    if (appManagerResult.itsFailure) return appManagerResult.cast();
    defineAppManager(appManagerResult.content);
    return voidResult;
  }

  @override
  FutureResult<EntityThreadConnection<T>> createEntityThread<T>({required T instance, bool omitIfExists = true}) {
    return _entityMutex.execute(() async {
      final existingConnection = entityConnections[T];
      if (existingConnection != null) {
        if (omitIfExists) {
          return existingConnection.asResultValue();
        } else {
          return NegativeResult.controller(
            code: ErrorCode.invalidFunctionality,
            message: FlexibleOration(message: 'An entity thread connection for type %1 already exists', textParts: [T.toString()]),
          );
        }
      }

      final newThreadResult = await SpawnEntityIsolate<T>(entityObject: instance, server: this).execute();
      if (newThreadResult.itsFailure) {
        return newThreadResult.cast();
      }

      entityConnections[T] = newThreadResult.content;
      newThreadResult.content.connection.onDispose.whenComplete(() => entityConnections.remove(T));

      return newThreadResult;
    });
  }

  @override
  EntityThreadConnection<T> service<T>() {
    final connection = entityConnections[T];
    return connection != null ? connection as EntityThreadConnection<T> : UnsupportedEntityThreadConnection<T>();
  }

  @override
  FutureResult<ThreadConnection> obtainConnectionFromIdentifier({required int threadIdentifier}) async {
    for (final item in externalConnections) {
      if (item.identifier == threadIdentifier) {
        return item.asResultValue();
      }
    }

    return NegativeResult.controller(
      code: ErrorCode.nonExistent,
      message: FlexibleOration(message: 'Thread #%1 does not exist', textParts: [threadIdentifier.toString()]),
    );
  }

  FutureResult<SendPort> obtainSendPortFromIdentifier({required int threadIdentifier}) async {
    final connectionResult = await obtainConnectionFromIdentifier(threadIdentifier: threadIdentifier);
    if (connectionResult.itsFailure) {
      return connectionResult.cast();
    }

    final connection = connectionResult.content;
    return getConnectionSendPort(connection: connection);
  }

  FutureResult<SendPort> obtainEntitySendPort<T>() async {
    final entityConnection = entityConnections[T];
    if (entityConnection == null) {
      return NegativeResult.controller(
        code: ErrorCode.nonExistent,
        message: FlexibleOration(message: 'No entity thread connection for type %1 exists', textParts: [T.toString()]),
      );
    }

    return entityConnection.dynamicCastResult<EntityThreadConnection<T>>().onCorrectFuture((x) => x.executeResult(function: _getEntitySendPortInClient<T>));
  }

  static FutureResult<SendPort> _getEntitySendPortInClient<T>(T item, InvocationParameters parameters) async {
    final clientConnectionResult = threadSystem.dynamicCastResult<IsolatedThreadClient>(
      errorMessage: const FixedOration(message: 'The thread connection is not a client, which is required to obtain the entity send port'),
    );
    if (clientConnectionResult.itsFailure) {
      return clientConnectionResult.cast();
    }

    final clientConnection = clientConnectionResult.content;
    final entity = clientConnection.entity;
    if (entity is! T) {
      return NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: FlexibleOration(message: 'The thread client does not have an entity of type %1', textParts: [T.toString()]),
      );
    }

    return clientConnection.createSendPort();
  }

  @override
  void performObjectDiscard() {
    super.performObjectDiscard();

    if (threadSystem == this) {
      threadSystem = const ThreadManagerInitializer();
    }
  }

  @override
  Result<T> getThreadEntity<T>() {
    return NegativeResult.controller(
      code: ErrorCode.invalidFunctionality,
      message: const FixedOration(message: 'Cannot get thread entity: only isolate thread client can process this request'),
    );
  }
}
