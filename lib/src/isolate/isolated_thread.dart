import 'dart:isolate';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/entity_thread_connection.dart';
import 'package:maxi_thread/src/isolate/communication/isolator_channel_initiation_point.dart';
import 'package:maxi_thread/src/isolate/connections/isolate_thread_connection.dart';
import 'package:maxi_thread/src/isolate/channels/isolate_thread_channel_manager.dart';
import 'package:maxi_thread/src/thread_connection.dart';
import 'package:maxi_thread/src/thread_manager.dart';
import 'package:maxi_thread/src/thread_singleton.dart';
import 'package:meta/meta.dart';

abstract class IsolatedThread with DisposableMixin, LifecycleHub implements ThreadManager {
  /// A set of external connections to other threads, allowing for communication and interaction with other threads in a multi-threaded application. This set is used to manage and track the connections established with other threads, enabling effective communication and coordination between threads while ensuring that resources are properly managed and cleaned up when connections are discarded.
  final externalConnections = <IsolateThreadConnection>{};

  /// A set of pending connections that are in the process of being initialized. These connections are not yet fully established and are awaiting confirmation before they can be used for communication.
  final pendingConnections = <IsolatorChannelInitiationPoint>{};

  /// A map of entity connections, associating each entity type with its corresponding thread connection. This allows for efficient management and retrieval of entity-specific connections within the isolated thread.
  final entityConnections = <Type, EntityThreadConnection>{};

  /// The channel manager is responsible for managing communication channels with the isolate thread, allowing for the creation and management of channels that facilitate communication between the main thread and the isolate thread. This component plays a crucial role in enabling effective communication and coordination between threads in a multi-threaded application, ensuring that resources are properly managed and that communication channels are established and maintained effectively.
  final channelManager = IsolateThreadChannelManager();

  final _threadData = <String, Object>{};

  @protected
  /// Creates a send port for communication with the isolate thread. If the thread has been discarded, it returns a negative result indicating that the thread is no longer available. Otherwise, it creates a new initiation point for the isolator channel, adds it to the pending connections, and waits for confirmation of its initialization. Once confirmed, it creates a channel from the pending initiation point and returns the send port for communication with the isolate thread. This method allows for effective management of communication channels with the isolate thread while handling potential errors and ensuring that operations are not performed on a discarded thread.
  Result<SendPort> createSendPort() {
    if (itWasDiscarded) {
      return NegativeResult.controller(
        code: ErrorCode.discontinuedFunctionality,
        message: const FixedOration(message: 'Isolated Thread was discarded'),
      );
    }
    final pending = joinDisposableObject(IsolatorChannelInitiationPoint());

    pendingConnections.add(pending);

    separateExecution(
      function: () async {
        final itsInitialize = await pending.waitConfirmation();
        pendingConnections.remove(pending);
        if (itsInitialize) {
          return await _createChannelFromPending(pending).logIfFails(errorName: 'IsolatedThread -> ObtainSendPort: Initilization failed');
        } else {
          return NegativeResult.controller(
            code: ErrorCode.discontinuedFunctionality,
            message: const FixedOration(message: 'The pending connection was not confirmed and was discarded'),
          );
        }
      },
    ).logIfFails(errorName: 'IsolatedThread -> ObtainSendPort: Failed to execute initialization function for pending connection');

    return pending.output.asResultValue<SendPort>();
  }

  /// A private method that creates a channel from a pending initiation point and adds the new connection to the set of external connections. This method is called once the initialization of the pending connection is confirmed, allowing for effective management of communication channels with the isolate thread while ensuring that resources are properly cleaned up in case of initialization failures. If the initialization is successful, it creates a new `IsolateThreadConnection` using the provided initiation point, obtains the thread data, and adds the new connection to the set of external connections. If there is an error during the initialization process, it disposes of the new connection and returns the error wrapped in a `Result` type, allowing for effective error handling and resource management in the context of managing communication channels with the isolate thread.
  FutureResult<void> _createChannelFromPending(IsolatorChannelInitiationPoint pending) async {
    final newConnection = joinDisposableObject(IsolateThreadConnection(channel: pending));
    final dataResult = await newConnection.obtaintThreadData();
    if (dataResult.itsFailure) {
      newConnection.dispose();
      return dataResult;
    }

    externalConnections.add(newConnection);
    //newConnection.onDispose.whenComplete(() => externalConnections.remove(newConnection));
    return voidResult;
  }

  @protected
  /// Obtains the send port for communication with the isolate thread based on the provided thread connection. This method executes a function in the isolate thread to retrieve the send port, allowing for effective communication with the isolate thread while handling potential errors and ensuring that operations are not performed on a discarded connection. If the connection is valid, it executes a function in the isolate thread to retrieve the send port and returns it wrapped in a `Result` type. If there is an error during execution, it returns the error wrapped in a `Result` type, allowing for effective error handling and communication about issues that may arise when attempting to obtain the send port for communication with the isolate thread.
  FutureResult<SendPort> getConnectionSendPort({required ThreadConnection connection}) {
    return connection.executeResult(function: _sendConnectionPort);
  }

  /// A static function that retrieves the send port for communication with the isolate thread. This function is executed in the isolate thread and accesses the thread manager to create a send port for communication. If the thread manager is not an instance of `IsolatedThread`, it returns a failure result indicating that only isolate threads can process this request. If the thread manager is valid, it creates a send port and returns it wrapped in a `Result` type, allowing for effective communication with the isolate thread while handling potential errors and ensuring that operations are not performed on an invalid thread manager.
  static FutureResult<SendPort> _sendConnectionPort(InvocationParameters parameters) async {
    final threadResult = threadSystem.dynamicCastResult<IsolatedThread>(errorMessage: const FixedOration(message: 'Cannot obtain connection send port: only isolate thread can process this request'));
    if (threadResult.itsFailure) {
      return threadResult.cast();
    }

    return threadResult.content.createSendPort();
  }

  @override
  Result<void> defineThreadObject<T extends Object>({required String name, required T object, bool removePrevious = true}) {
    final exists = _threadData[name];
    if (exists != null) {
      if (removePrevious) {
        _threadData.remove(name);
        if (exists is Disposable) {
          exists.dispose();
        }
      } else {
        return NegativeResult.controller(
          code: ErrorCode.invalidFunctionality,
          message: FlexibleOration(message: 'An object with name %1 is already defined in the thread', textParts: [name]),
        );
      }
    }
    _threadData[name] = object;

    if (object is Disposable) {
      object.onDispose.whenComplete(() {
        if (_threadData[name] == object) {
          _threadData.remove(name);
        }
      });
    }
    return voidResult;
  }

  @override
  Result<T> obtainThreadObject<T extends Object>({required String name}) {
    final object = _threadData[name];
    if (object == null) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'No object with name %1 is defined in the thread', textParts: [name]),
      );
    }
    if (object is! T) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'Object with name %1 is not of type %2 (object is %3)', textParts: [name, T.toString(), object.runtimeType.toString()]),
      );
    }
    return ResultValue(content: object);
  }

  @override
  Result<bool> hasThreadObject<T extends Object>({required String name}) {
    final object = _threadData[name];
    if (object == null) {
      return ResultValue(content: false);
    }
    if (object is! T) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'Object with name %1 is not of type %2 (object is %3)', textParts: [name, T.toString(), object.runtimeType.toString()]),
      );
    }
    return ResultValue(content: true);
  }

  @override
  Result<void> removeThreadObject<T extends Object>({required String name}) {
    final object = _threadData[name];
    if (object == null) {
      return voidResult;
    }
    if (object is! T) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'Object with name %1 is not of type %2 (object is %3)', textParts: [name, T.toString(), object.runtimeType.toString()]),
      );
    }
    _threadData.remove(name);
    if (object is Disposable) {
      object.dispose();
    }
    return voidResult;
  }

  @override
  /// Disposes of the thread by clearing all external connections, pending connections, and entity connections. This ensures that all resources associated with the thread are properly cleaned up when the thread is discarded, preventing memory leaks and ensuring that ongoing tasks are appropriately terminated in response to the disposal of the thread.
  void dispose() {
    super.dispose();

    externalConnections.clear();
    pendingConnections.clear();
    entityConnections.clear();
  }
}
