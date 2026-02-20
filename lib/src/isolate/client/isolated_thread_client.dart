import 'dart:isolate';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/entity_thread_connection.dart';
import 'package:maxi_thread/src/isolate/communication/isolator_channel_end_point.dart';
import 'package:maxi_thread/src/isolate/client/entity_thread_mask_connection.dart';
import 'package:maxi_thread/src/isolate/connections/isolate_thread_connection.dart';
import 'package:maxi_thread/src/isolate/isolated_thread.dart';
import 'package:maxi_thread/src/isolate/server/isolated_thread_server.dart';
import 'package:maxi_thread/src/isolate/server/masks/entity_isolate_thread_connection.dart';
import 'package:maxi_thread/src/isolate/server/masks/self_entity_thread_connection.dart';
import 'package:maxi_thread/src/thread_connection.dart';
import 'package:maxi_thread/src/thread_singleton.dart';

/// Represents a client thread that runs in an isolate and communicates with a server thread to manage entity threads and perform various operations. It provides methods for creating threads, obtaining connections, and accessing entity thread connections, while handling the underlying communication and connection logic with the server.
/// The `IsolatedThreadClient` class extends the `IsolatedThread` class and implements the necessary functionality to establish a connection with the server, manage entity threads, and facilitate communication between threads in an isolated environment.
class IsolatedThreadClient extends IsolatedThread {
  @override
  final int identifier;

  @override
  final String name;

  @override
  late final ThreadConnection serverConnection;

  dynamic entity;

  /// Creates an isolated thread client with the given [identifier] and [name], and establishes a connection with the server using the provided [channel].
  IsolatedThreadClient({required this.identifier, required this.name, required IsolatorChannelEndPoint channel}) {
    final server = IsolateThreadConnection(channel: channel, identifier: 0, name: 'Isolated Thread Server');
    externalConnections.add(server);
    serverConnection = server;
    serverConnection.onDispose.whenComplete(dispose);
  }

  ////////////////////////////// ENTITY CREATION AND MANAGEMENT LOGIC //////////////////////////////
  /** */

  @override
  /// Provides a service interface for accessing an entity thread connection of type [T]. If the current thread manages an entity of type [T], it returns a self-connection. If an entity thread connection for type [T] already exists, it returns that connection. Otherwise, it creates a new mask connection for the entity thread and returns it.
  FutureResult<EntityThreadConnection<T>> createEntityThread<T>({required T instance, bool omitIfExists = true}) async {
    if (entity != null && entity is T) {
      if (omitIfExists) {
        return SelfEntityThreadConnection<T>(instance: entity as T).asResultValue();
      } else {
        return NegativeResult.controller(
          code: ErrorCode.implementationFailure,
          message: FlexibleOration(message: 'This is the thread that manages %1', textParts: [T.toString()]),
        );
      }
    }

    final exists = entityConnections[T];
    if (exists != null) {
      if (omitIfExists) {
        return exists.asResultValue();
      } else {
        return NegativeResult.controller(
          code: ErrorCode.implementationFailure,
          message: FlexibleOration(message: 'Entity thread %1 of type already exists', textParts: [T.toString()]),
        );
      }
    }

    final spawResult = await serverConnection.executeResult(function: _createEntityThreadInServer<T>, parameters: InvocationParameters.list([instance, omitIfExists]));
    if (spawResult.itsFailure) {
      return spawResult.cast();
    }

    final connectionResult = await connectSendPort(spawResult.content);
    if (connectionResult.itsFailure) {
      return connectionResult.cast();
    }

    final newEntityConnection = EntityIsolateThreadConnection<T>(connectionResult.content);
    entityConnections[T] = newEntityConnection;
    return newEntityConnection.asResultValue();
  }

  /// Provides a service interface for accessing an entity thread connection of type [T]. If the current thread manages an entity of type [T], it returns a self-connection. If an entity thread connection for type [T] already exists, it returns that connection. Otherwise, it creates a new mask connection for the entity thread and returns it.
  static FutureResult<SendPort> _createEntityThreadInServer<T>(InvocationParameters parameters) async {
    final serverResult = threadSystem.dynamicCastResult<IsolatedThreadServer>(errorMessage: const FixedOration(message: 'Cannot create entity thread: only isolate thread server can process this request'));
    if (serverResult.itsFailure) {
      return serverResult.cast();
    }

    final spawnResult = await serverResult.content.createEntityThread(instance: parameters.first<T>(), omitIfExists: parameters.second<bool>());
    if (spawnResult.itsFailure) {
      return spawnResult.cast();
    }

    return spawnResult.content.executeResult(function: _obtaintSendPortFromEntityThread<T>);
  }

  static FutureResult<SendPort> _obtaintSendPortFromEntityThread<T>(T instance, InvocationParameters parameters) async {
    final clientThreadResult = threadSystem.dynamicCastResult<IsolatedThreadClient>(errorMessage: const FixedOration(message: 'The thread connection is not an client, which is required to execute entity functions'));
    if (clientThreadResult.itsFailure) {
      return clientThreadResult.cast();
    }
    return clientThreadResult.content.createSendPort();
  }

  ////////////////////////////// SEND PORT CONNECTION LOGIC //////////////////////////////
  /** */

  /// Establishes a connection with the server using the provided [sendPort] and returns the resulting thread connection. If the connection fails, it returns the corresponding error.
  FutureResult<ThreadConnection> connectSendPort(SendPort sendPort) async {
    final channel = IsolatorChannelEndPoint(sendPoint: sendPort);
    final connection = IsolateThreadConnection(channel: channel);
    final initResult = await connection.obtaintThreadData();
    if (initResult.itsFailure) {
      return initResult.cast();
    }

    externalConnections.add(joinDisposableObject(connection));
    connection.onDispose.whenComplete(() => externalConnections.remove(connection));
    return connection.asResultValue();
  }

  /// Obtains a send port for a connection with the specified [threadIdentifier] from the server. If the connection is successful, it returns the send port; otherwise, it returns the corresponding error.
  static FutureResult<SendPort> _obtainConnectionPortInServer(InvocationParameters parameters) async {
    final threadResult = threadSystem.dynamicCastResult<IsolatedThreadServer>(errorMessage: const FixedOration(message: 'Cannot obtain connection send port: only isolate thread server can process this request'));
    if (threadResult.itsFailure) {
      return threadResult.cast();
    }

    final connectionResult = await threadResult.content.obtainConnectionFromIdentifier(threadIdentifier: parameters.first<int>());
    if (connectionResult.itsFailure) {
      return connectionResult.cast();
    }

    return threadResult.content.getConnectionSendPort(connection: connectionResult.content);
  }

  ////////////////////////////// THREAD CREATION LOGIC //////////////////////////////
  /** */

  @override
  /// Creates a new thread with the specified [name] and optional [initializers], and establishes a connection with the server. If the thread creation is successful, it returns the resulting thread connection; otherwise, it returns the corresponding error.
  FutureResult<ThreadConnection> createThread({required String name, List<Functionality<dynamic>> initializers = const []}) async {
    final sendPortResult = await serverConnection.executeResult(parameters: InvocationParameters.list([name, initializers]), function: _createThreadInServer);
    if (sendPortResult.itsFailure) {
      return sendPortResult.cast();
    }
    return await connectSendPort(sendPortResult.content);
  }

  /// Creates a new thread with the specified [name] and optional [initializers], and establishes a connection with the server. If the thread creation is successful, it returns the resulting thread connection; otherwise, it returns the corresponding error.
  static FutureResult<SendPort> _createThreadInServer(InvocationParameters parameters) async {
    final threadResult = threadSystem.dynamicCastResult<IsolatedThreadServer>(errorMessage: const FixedOration(message: 'Cannot create thread: only isolate thread server can process this request'));
    if (threadResult.itsFailure) {
      return threadResult.cast();
    }

    final newConnectionResult = await threadResult.content.createThread(name: parameters.first<String>(), initializers: parameters.second<List<Functionality<dynamic>>>());
    if (newConnectionResult.itsFailure) {
      return newConnectionResult.cast();
    }

    return threadResult.content.getConnectionSendPort(connection: newConnectionResult.content);
  }

  ////////////////////////////// EXTERNAL ENTITY CONNECTION LOGIC //////////////////////////////
  /** */

  /// Provides a service interface for accessing an entity thread connection of type [T]. If the current thread manages an entity of type [T], it returns a self-connection. If an entity thread connection for type [T] already exists, it returns that connection. Otherwise, it creates a new mask connection for the entity thread and returns it.
  FutureResult<EntityThreadConnection<T>> obtainEntityThread<T>() async {
    if (entity != null && entity is T) {
      return SelfEntityThreadConnection<T>(instance: entity as T).asResultValue();
    }

    final exists = entityConnections[T];
    if (exists != null) {
      return exists.dynamicCastResult<EntityThreadConnection<T>>(
        errorMessage: FlexibleOration(message: 'The entity thread connection for type %1 has an invalid type', textParts: [T.toString()]),
      );
    }

    final sendPortResult = await serverConnection.executeResult(function: _obtainEntityThreadInServer<T>);
    if (sendPortResult.itsFailure) {
      return sendPortResult.cast();
    }
    final connectionResult = await connectSendPort(sendPortResult.content);
    if (connectionResult.itsFailure) {
      return connectionResult.cast();
    }

    final newConnection = EntityIsolateThreadConnection<T>(connectionResult.content);
    entityConnections[T] = newConnection;

    return newConnection.asResultValue();
  }

  /// Provides a service interface for accessing an entity thread connection of type [T]. If the current thread manages an entity of type [T], it returns a self-connection. If an entity thread connection for type [T] already exists, it returns that connection. Otherwise, it creates a new mask connection for the entity thread and returns it.
  static FutureResult<SendPort> _obtainEntityThreadInServer<T>(InvocationParameters parameters) async {
    final serverResult = threadSystem.dynamicCastResult<IsolatedThreadServer>(errorMessage: const FixedOration(message: 'Cannot obtain entity thread: only isolate thread server can process this request'));
    if (serverResult.itsFailure) {
      return serverResult.cast();
    }

    final exists = serverResult.content.entityConnections[T];
    if (exists == null) {
      return NegativeResult.controller(
        code: ErrorCode.nonExistent,
        message: FlexibleOration(message: 'No entity thread connection for type %1 was found in the server', textParts: [T.toString()]),
      );
    }

    return exists
        .dynamicCastResult<EntityThreadConnection<T>>(
          errorMessage: FlexibleOration(message: 'The entity thread connection for type %1 has an invalid type', textParts: [T.toString()]),
        )
        .onCorrectFuture((x) => x.executeResult(function: _obtaintSendPortFromEntityThread<T>));
  }

  ////////////////////////////// SERVICE INTERFACE LOGIC //////////////////////////////
  /** */

  @override
  /// Provides a service interface for accessing an entity thread connection of type [T]. If the current thread manages an entity of type [T], it returns a self-connection. If an entity thread connection for type [T] already exists, it returns that connection. Otherwise, it creates a new mask connection for the entity thread and returns it.
  EntityThreadConnection<T> service<T>() {
    if (entity != null && entity is T) {
      return SelfEntityThreadConnection<T>(instance: entity as T);
    }

    final exists = entityConnections[T];
    if (exists != null) {
      return exists as EntityThreadConnection<T>;
    }

    final newMask = EntityThreadMaskConnection<T>(serverConnection: serverConnection, clientConnection: this);
    entityConnections[T] = newMask;
    return newMask;
  }

  ////////////////////////////// IDENTIFIER CONNECTION LOGIC //////////////////////////////
  /** */

  @override
  /// Obtains a connection with the specified [threadIdentifier] from the server. If the connection is successful, it returns the thread connection; otherwise, it returns the corresponding error.
  FutureResult<ThreadConnection> obtainConnectionFromIdentifier({required int threadIdentifier}) async {
    if (threadIdentifier == 0) {
      return serverConnection.asResultValue();
    }

    final exists = externalConnections.selectItem((thread) => thread.identifier == threadIdentifier);
    if (exists != null) {
      return exists.asResultValue();
    }

    final sendPortResult = await serverConnection.executeResult(parameters: InvocationParameters.only(threadIdentifier), function: _obtainConnectionPortInServer);
    if (sendPortResult.itsFailure) {
      return sendPortResult.cast();
    }
    return await connectSendPort(sendPortResult.content);
  }

  @override
  /// Disposes of the thread client by closing the connection with the server and exiting the isolate after a short delay.
  void performObjectDiscard() {
    super.performObjectDiscard();
    serverConnection.dispose();
    Future.delayed(const Duration(milliseconds: 10)).whenComplete(() {
      Isolate.exit();
    });
  }

  @override
  Result<T> getThreadEntity<T>() {
    if (entity == null) {
      return NegativeResult.controller(
        code: ErrorCode.nonExistent,
        message: FlexibleOration(message: 'This thread does not manage any entity of type %1', textParts: [T.toString()]),
      );
    }

    if (entity is T) {
      return ResultValue(content: entity as T);
    } else {
      return NegativeResult.controller(
        code: ErrorCode.invalidValue,
        message: FlexibleOration(message: 'The entity managed by this thread cannot be cast to type %1', textParts: [T.toString()]),
      );
    }
  }
}
