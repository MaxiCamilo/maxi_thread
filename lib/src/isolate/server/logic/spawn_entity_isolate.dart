import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/isolate/client/isolated_thread_client.dart';
import 'package:maxi_thread/src/isolate/server/isolated_thread_server.dart';
import 'package:maxi_thread/src/isolate/server/masks/entity_isolate_thread_connection.dart';
import 'package:maxi_thread/src/thread_connection.dart';
import 'package:maxi_thread/src/thread_singleton.dart';

/// The `SpawnEntityIsolate` class is responsible for spawning a new isolate thread and initializing it with a specific entity object. It takes an entity object and an isolated thread server as parameters, and it manages the lifecycle of the spawned isolate thread. The class provides functionality to create a new thread, execute initialization logic within the thread, and handle the results of the initialization process. If the initialization is successful, it returns an `EntityIsolateThreadConnection` that allows for communication with the spawned isolate thread. If there are any errors during the process, it handles them appropriately and ensures that resources are cleaned up when necessary. The `runFuncionality` method is the core of this class, where it creates a new thread, initializes it with the entity object, and returns the connection to the caller. The static method `_initializeEntityInThread` is executed within the spawned isolate thread to perform the actual initialization of the entity, ensuring that the thread is properly set up to manage the entity and handle its lifecycle effectively.
class SpawnEntityIsolate<T> with FunctionalityMixin<EntityIsolateThreadConnection<T>> {
  final T entityObject;
  final IsolatedThreadServer server;

  ThreadConnection? _newConnection;

  SpawnEntityIsolate({required this.entityObject, required this.server});

  @override
  /// Overrides the `onFinish` method to handle the completion of the functionality execution. If the result of the execution is a failure, it attempts to request the closure of the newly spawned thread connection to ensure that resources are cleaned up properly. This method ensures that any resources associated with a failed thread initialization are appropriately released, preventing potential memory leaks or orphaned threads in the system.
  void onFinish(Result<EntityIsolateThreadConnection<T>> result) {
    super.onFinish(result);
    if (result.itsFailure) {
      _newConnection?.requestClosure().logIfFails(errorName: 'SpawnEntityIsolate -> onFinish: Failed to request closure of thread connection');
    }
  }

  @override
  /// Executes the functionality of spawning a new isolate thread and initializing it with the provided entity object. This method creates a new thread using the isolated thread server, initializes the entity within the thread, and returns a result containing the connection to the newly spawned isolate thread. If any step in the process fails, it handles the failure appropriately and ensures that resources are cleaned up.
  Future<Result<EntityIsolateThreadConnection<T>>> runFuncionality() async {
    final newConnectionResult = await server.createThread(name: entityObject.runtimeType.toString(), initializers: const []);
    if (newConnectionResult.itsFailure) {
      return newConnectionResult.cast();
    }
    _newConnection = newConnectionResult.content;
    final initResult = await _newConnection!.executeResult(parameters: InvocationParameters.only(entityObject), function: _initializeEntityInThread<T>);
    if (initResult.itsFailure) {
      return initResult.cast();
    }

    return EntityIsolateThreadConnection<T>(_newConnection!).asResultValue();
  }

  /// A static function that initializes the entity within the spawned isolate thread. This function is executed in the context of the newly spawned thread and takes the entity object as a parameter. It checks if the thread is an instance of `IsolatedThreadClient`, and if so, it assigns the entity to the thread's entity property. If the entity implements `Initializable`, it calls its `initialize` method, and if it implements `AsynchronouslyInitialized`, it awaits its asynchronous initialization. The function returns a void result if the initialization is successful, or an appropriate failure result if any step in the process fails. This function ensures that the entity is properly initialized within the context of the isolate thread, allowing for effective management of the entity's lifecycle and interactions within the thread.
  static FutureResult<void> _initializeEntityInThread<T>(InvocationParameters parameters) async {
    final entity = parameters.first<T>();
    final threadResult = threadSystem.dynamicCastResult<IsolatedThreadClient>(errorMessage: const FixedOration(message: 'Cannot initialize thread as entity: only client threads can be defined as entity '));

    if (threadResult.itsFailure) {
      return threadResult.cast();
    }

    final thread = threadResult.content;
    if (thread.entity != null) {
      return NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: FlexibleOration(message: 'The thread already has an entity assigned as %1, cannot assign another one (%2)', textParts: [thread.entity.runtimeType, entity.runtimeType]),
      );
    }

    thread.entity = entity;

    if (entity is Initializable) {
      final initResult = entity.initialize();
      if (initResult.itsFailure) {
        return initResult.cast();
      }
    }

    if (entity is AsynchronouslyInitialized) {
      final asyncInitResult = await entity.initialize();
      if (asyncInitResult.itsFailure) {
        return asyncInitResult.cast();
      }
    }

    return voidResult;
  }
}
