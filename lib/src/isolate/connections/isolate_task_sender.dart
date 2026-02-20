import 'dart:async';
import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/isolate/communication/isolator_channel.dart';
import 'package:maxi_thread/src/isolate/connections/isolate_message.dart';
import 'package:rxdart/rxdart.dart';

/// Represents a sender for executing tasks in an isolate thread through an isolator channel. The `IsolateTaskSender` class manages the sending of task requests, handling of confirmations, and reception of results or messages from the isolate thread. It provides methods for executing functions that return results or results wrapped in a `Result` type, allowing for structured communication and error handling between threads in an isolated environment. The class also manages the lifecycle of tasks and ensures proper disposal of resources when the sender is discarded.
class IsolateTaskSender with DisposableMixin {
  /// The [channel] through which the sender communicates with the isolate thread, sending task requests and receiving confirmations, results, or messages.
  final IsolatorChannel channel;
  /// The name of the thread in which the sender is operating, used for logging and identification purposes.
  final String threadName;

  /// A mutex used to synchronize the sending of task requests and the handling of confirmations, ensuring that only one request is sent at a time and that confirmations are properly matched to their corresponding requests.
  final _confirmationMutex = Mutex();
  /// A list that keeps track of the currently active tasks, allowing the sender to manage their lifecycle and ensure proper disposal when necessary. Each task is represented by an instance of the `_IsolateTaskInstance` class, which encapsulates the details and state of an individual task being executed in the isolate thread.
  final _tasks = <_IsolateTaskInstance>[];

  /// A completer that is used to wait for a confirmation message from the isolate thread after sending a task request. When a request is sent, this completer is initialized and will be completed when a confirmation message with the corresponding ID is received. If a confirmation is not received within a specified timeout period, the completer will complete with an error, allowing the sender to handle cases where the isolate thread does not respond in a timely manner. This mechanism ensures that the sender can effectively manage the communication and synchronization of task requests and confirmations with the isolate thread.
  Completer<Result<IsolateMessageStatus>>? _confirmationCompleter;

  IsolateTaskSender({required this.channel, required this.threadName}) {
    /// Listens for incoming isolate messages on the channel and processes them using the `_processMessage` method. When the channel is closed, it triggers the disposal of the sender to clean up resources and ensure proper shutdown of the thread.
    channel.stream.whereType<IsolateMessageStatus>().listen(_processMessage, onDone: () => dispose());
  }

  /// Executes a function in the isolate thread that returns a result of type `T`. The method sends a task request to the isolate thread, waits for a confirmation, and then waits for the result to be returned. If the function execution is successful, it returns the result wrapped in a `Result` type. If there is an error during execution or if the isolate thread does not respond in a timely manner, it returns an appropriate error wrapped in a `Result` type. This method allows for structured communication and error handling when executing tasks in the isolate thread.
  Future<Result<T>> execute<T>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<T> Function(InvocationParameters para) function}) async {
    final sendResult = await _sendRequest(
      IsolateMessageRequest(
        type: IsolateMessageRequestType.createFunction,
        id: 0,
        payload: IsolateMessageResultFunction<T>(function: function, parameters: parameters, returnsResult: false),
      ),
    );

    if (sendResult.itsFailure) {
      return sendResult.cast();
    }

    final task = _createTaskInstance<T>(id: sendResult.content.id);
    return await task.waitResult();
  }

  /// Executes a function in the isolate thread that returns a `Result` of type `T`. Similar to the `execute` method, it sends a task request to the isolate thread and waits for a confirmation. However, this method is specifically designed for functions that return a `Result` type, allowing for more structured error handling and communication of success or failure. If the function execution is successful, it returns the result as a `Result` type. If there is an error during execution or if the isolate thread does not respond in a timely manner, it returns an appropriate error wrapped in a `Result` type. This method provides enhanced capabilities for managing and handling results when executing tasks in the isolate thread.
  Future<Result<T>> executeResult<T>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<T>> Function(InvocationParameters para) function}) async {
    final sendResult = await _sendRequest(
      IsolateMessageRequest(
        type: IsolateMessageRequestType.createFunction,
        id: 0,
        payload: IsolateMessageResultFunction<T>(function: function, parameters: parameters, returnsResult: true),
      ),
    );

    if (sendResult.itsFailure) {
      return sendResult.cast();
    }

    final task = _createTaskInstance<T>(id: sendResult.content.id);
    return await task.waitResult();
  }

  @override
  /// Disposes of the sender by disposing of all active tasks and clearing the task list. This ensures that all resources associated with the sender and its tasks are properly cleaned up when the sender is discarded, preventing memory leaks and ensuring that any ongoing tasks are appropriately terminated.
  void performObjectDiscard() {
    _tasks.lambda((x) => x.dispose());
    _tasks.clear();
  }

  /// Handles the sending of a task request to the isolate thread and waits for a confirmation message. The method uses a mutex to ensure that only one request is sent at a time, and it manages the lifecycle of the confirmation completer to handle timeouts and errors effectively. If the request is sent successfully, it waits for a confirmation message with the corresponding ID. If a confirmation is not received within the specified timeout period, it returns an appropriate error wrapped in a `Result` type. This method ensures that the sender can effectively manage the communication and synchronization of task requests and confirmations with the isolate thread.
  FutureResult<IsolateMessageStatus> _sendRequest(IsolateMessageRequest message) {
    return _confirmationMutex.execute(() async {
      await Future.delayed(Duration.zero);
      if (itWasDiscarded) {
        return NegativeResult.controller(
          code: ErrorCode.implementationFailure,
          message: FixedOration(message: 'A request was attempted to be sent to the isolate, but the sender was already discarded. Thread name: $threadName'),
        );
      }
      final sendResult = channel.send(message);
      if (sendResult.itsFailure) {
        return sendResult.cast();
      }
      _confirmationCompleter = Completer<Result<IsolateMessageStatus>>();

      return _confirmationCompleter!.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          _confirmationCompleter = null;
          return NegativeResult.controller(
            code: ErrorCode.timeout,
            message: FlexibleOration(message: 'The execution of a function was requested, but it took too long to respond to the execution request', textParts: [threadName]),
          );
        },
      );
    });
  }

  /// Creates a new task instance for a given task ID and manages its lifecycle. The method adds the new task instance to the list of active tasks and sets up a listener to remove the task from the list when it is disposed. Additionally, it checks for the presence of a zone heart and sets up a listener to handle the disposal of the task if the heart is disposed, ensuring that tasks are properly cleaned up in response to changes in the application lifecycle. This method allows the sender to effectively manage the lifecycle of tasks and ensure proper disposal when necessary, preventing memory leaks and ensuring that ongoing tasks are appropriately terminated in response to application lifecycle events.
  _IsolateTaskInstance<T> _createTaskInstance<T>({required int id}) {
    final task = _IsolateTaskInstance<T>(id: id);
    _tasks.add(task);
    task.onDispose.whenComplete(() => _tasks.remove(task));

    final heart = LifeCoordinator.tryGetZoneHeart;

    if (heart != null) {
      final onHeartDispose = heart.onDispose.whenComplete(() {
        if (task.itWasDiscarded) return;
        channel.send(IsolateMessageRequest(type: IsolateMessageRequestType.cancel, id: id, payload: null));
        task.dispose();
      });
      task.onDispose.whenComplete(() => onHeartDispose.ignore());
    }

    return task;
  }

  /// Processes incoming isolate messages by determining the type of message and handling it accordingly. For confirmation messages, it completes the confirmation completer with the received status. For execution result messages, it finds the corresponding task instance and defines its result. For regular messages, it finds the corresponding task instance and passes the message to it for handling. The method also includes error handling to log cases where a confirmation is received without a pending completer or when a message is received for a non-existent task, ensuring that the sender can effectively manage and respond to incoming messages from the isolate thread. This method is crucial for maintaining the communication and synchronization between the sender and the isolate thread, allowing for effective handling of task requests, confirmations, and results.
  void _processMessage(IsolateMessageStatus event) {
    switch (event.type) {
      case IsolateMessageStatusType.confirmation:
        if (_confirmationCompleter != null && !_confirmationCompleter!.isCompleted) {
          _confirmationCompleter!.complete(ResultValue(content: event));
          _confirmationCompleter = null;
        } else {
          log('[IsolateTaskSender] Received an isolate message confirmation for thread $threadName, but there was no pending confirmation completer');
        }
        break;
      case IsolateMessageStatusType.executeResult:
        final task = _tasks.selectItem((x) => x.id == event.id);
        if (task != null) {
          task.defineResult(event.payload);
        } else {
          log('[IsolateTaskSender] Received an isolate message with an execution result for thread $threadName, but there was no matching task with id ${event.id}');
        }
        break;
      case IsolateMessageStatusType.message:
        final task = _tasks.selectItem((x) => x.id == event.id);
        if (task != null) {
          task.receiveMessage(event.payload);
        } else {
          log('[IsolateTaskSender] Received an isolate message for thread $threadName, but there was no matching task with id ${event.id}');
        }
        break;
    }
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/** */

/// Represents a connection for sending tasks to an isolate thread that is associated with a specific entity type `T`. The `IsolateEntityTaskSender` class manages the sending of task requests related to a particular entity type, allowing for structured communication and task management in an isolated environment. It provides methods for executing functions that return results or results wrapped in a `Result` type, specifically for tasks related to the entity type `T`. This class is designed to facilitate the execution of tasks in an isolate thread while maintaining a clear association with a specific entity type, enabling effective handling of tasks and communication in a concurrent environment.
class _IsolateTaskInstance<T> with DisposableMixin {
  final int id;

  final _completer = Completer<Result<T>>();
  late final List<Function> _interactiveFunctions;

  _IsolateTaskInstance({required this.id}) {
    _interactiveFunctions = InteractiveSystem.getAllSenders();
  }

  /// Handles the reception of a message for the task by determining its type and processing it accordingly. If the message is an interactive message, it reacts to it using the available interactive functions. If the message is of an unexpected type, it logs a warning message indicating that an unexpected message type was received for the task. This method allows the task instance to effectively manage incoming messages and interact with them based on their type, facilitating communication and interaction within the isolate thread.
  void receiveMessage(dynamic message) {
    if (_completer.isCompleted) {
      log('[IsolateTaskInstance] Received a message for a task #$id that is already completed. Message: ${message.message}');
      return;
    }
    if (message is IsolateTaskInteractiveMessage) {
      message.react(interactiveFunctions: _interactiveFunctions);
    } else {
      log('[IsolateTaskInstance] Received a message for a task #$id with an unexpected type: ${message.runtimeType}');
    }
  }

  /// Waits for the result of the task to be defined and returns it as a `Result` type. If the result is defined successfully, it returns the result wrapped in a `Result` type. If there is an error during execution or if the task is discarded before a result is defined, it returns an appropriate error wrapped in a `Result` type. This method allows for structured communication and error handling when waiting for the result of a task being executed in the isolate thread.
  FutureResult<T> waitResult() => _completer.future;

  /// Defines the result of the task by completing the completer with the provided result. If the result is of type `Result<T>`, it completes the completer with that result. If the result is of type `T`, it wraps it in a `ResultValue<T>` and completes the completer. If the result is of an unexpected type, it logs a warning message and completes the completer with an error indicating that an unexpected type was received. This method ensures that the result of the task is properly defined and that any issues with unexpected result types are logged for debugging purposes.
  void defineResult(dynamic result) {
    if (_completer.isCompleted) {
      log('[IsolateTaskInstance] Attempted to define a result for task #$id, but it is already completed. Result: $result');
      return;
    }
    if (result is Result<T>) {
      _completer.complete(result);
    } else if (result is T) {
      _completer.complete(ResultValue<T>(content: result));
    } else {
      log('[IsolateTaskInstance] Attempted to define a result for task #$id with an unexpected type: ${result.runtimeType}. Result: $result');
      _completer.complete(
        NegativeResult.controller(
          code: ErrorCode.implementationFailure,
          message: FlexibleOration(
            message: 'The isolate task #%1 attempted to define a result with an unexpected type. Expected type: Result<%2>, actual type: %3',
            textParts: [id, T.toString(), result.runtimeType.toString()],
          ),
        ),
      );
    }

    dispose();
  }

  @override
  /// Disposes of the task instance by completing the completer with a cancellation result if it has not already been completed. This ensures that any waiting operations for the task's result are properly notified of the cancellation, allowing for effective cleanup and resource management when the task is discarded.
  void performObjectDiscard() {
    if (!_completer.isCompleted) {
      _completer.complete(CancelationResult<T>());
    }
  }
}
