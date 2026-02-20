import 'dart:async';
import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/isolate/communication/isolator_channel.dart';
import 'package:maxi_thread/src/isolate/connections/isolate_message.dart';
import 'package:maxi_thread/src/thread_connection.dart';
import 'package:maxi_thread/src/thread_manager.dart';
import 'package:maxi_thread/src/thread_singleton.dart';
import 'package:rxdart/rxdart.dart';

/// Represents a processor for handling tasks received through an isolator channel in an isolate thread. It listens for incoming task requests, executes the corresponding functions, and sends back the results or errors through the channel. The `IsolateTaskProcessor` class manages the lifecycle of tasks and ensures proper communication between threads in an isolated environment.
class IsolateTaskProcessor with DisposableMixin, LifecycleHub {
  /// The [channel] through which the processor receives task requests and sends back results or errors.
  final IsolatorChannel channel;

  /// The name of the thread in which the processor is running, used for logging and identification purposes.
  final String threadName;

  final ThreadConnection threadConnection;

  /// A map that keeps track of the currently executing tasks, where the key is the task ID and the value is the corresponding `AsyncExecutor` instance. This allows the processor to manage and cancel tasks as needed, ensuring efficient handling of concurrent operations within the isolate thread.
  final _currentTask = <int, AsyncExecutor>{};

  /// A static variable that keeps track of the last assigned task ID, used to generate unique IDs for incoming task requests. This variable is incremented each time a new task is created, ensuring that each task has a distinct identifier for tracking and communication purposes.
  int _lastTaskId = 1;

  IsolateTaskProcessor({required this.channel, required this.threadName, required this.threadConnection}) {
    /// Listens for incoming task requests on the channel and processes them using the `_processRequest` method. When the channel is closed, it triggers the disposal of the processor to clean up resources and ensure proper shutdown of the thread.
    channel.stream.whereType<IsolateMessageRequest>().listen(_processRequest, onDone: dispose);
  }

  /// Handles the execution of a task by sending a confirmation message back to the sender, creating an `AsyncExecutor` for the task, and managing the communication of results or errors through the channel. The method takes a function that defines the logic to be executed for the task, and it ensures that the results are sent back to the sender in a structured manner, allowing for effective handling of concurrent tasks within the isolate thread.
  Future<void> _confirmTask(FutureOr<Result> Function(int id) function) async {
    final id = _lastTaskId;
    _lastTaskId += 1;
    final sendConfirmationResult = channel.send(IsolateMessageStatus(type: IsolateMessageStatusType.confirmation, id: id, payload: null));
    if (sendConfirmationResult.itsFailure) {
      log('[IsolateTaskProcessor] Failed to send a confirmation message for task with id $id in thread $threadName. Error: $sendConfirmationResult');
      return;
    }

    final task = AsyncExecutor(function: () => function(id));
    joinDisposableObject(task);

    task.createListenerStream().listen(
      (x) {
        final sendResult = channel.send(IsolateMessageStatus(type: IsolateMessageStatusType.message, id: id, payload: x));
        if (sendResult.itsFailure) {
          log('[IsolateTaskProcessor] Failed to send an execution result message for task with id $id in thread $threadName. Error: $sendResult');
        }
      },
      onError: (e) {
        final sendResult = channel.send(IsolateMessageStatus(type: IsolateMessageStatusType.message, id: id, payload: e));
        if (sendResult.itsFailure) {
          log('[IsolateTaskProcessor] Failed to send an execution result message for task with id $id in thread $threadName. Error: $sendResult');
        }
      },
    );

    _currentTask[id] = task;
    task.onDispose.whenComplete(() => _currentTask.remove(id));

    await Future.delayed(Duration.zero);
    final result = await task.waitResult(zoneValues: {ThreadManager.kThreadManagerZone: threadSystem, ThreadConnection.kThreadConnectionZone: threadConnection});
    final sendResult = channel.send(IsolateMessageStatus(type: IsolateMessageStatusType.executeResult, id: id, payload: result));
    if (sendResult.itsFailure) {
      log('[IsolateTaskProcessor] Failed to send an execution result message for task with id $id in thread $threadName. Error: $sendResult');
      return;
    }
  }

  /// Processes incoming task requests by determining the type of request and executing the corresponding logic. For "createFunction" requests, it creates a new task using the provided function and manages its execution. For "cancel" requests, it disposes of the corresponding task to stop its execution. The method also handles any errors that may occur during the processing of requests and logs them for debugging purposes. It ensures that the processor can effectively manage and respond to various types of task requests within the isolate thread, facilitating efficient handling of concurrent operations and communication between threads.
  void _processRequest(IsolateMessageRequest event) {
    switch (event.type) {
      case IsolateMessageRequestType.createFunction:
        _createFunction(event);
        break;
      case IsolateMessageRequestType.message:
        throw UnimplementedError('IsolateTaskProcessor does not process messages of type "message". Received message with id ${event.id} in thread $threadName.');
      case IsolateMessageRequestType.cancel:
        _currentTask[event.id]?.dispose();
        break;
    }
  }

  /// Handles the creation of a new task based on the incoming request by executing the provided function and managing the communication of results or errors through the channel. The method takes an `IsolateMessageRequest` event, extracts the function to be executed from the payload, and uses the `_confirmTask` method to manage the execution and communication of results for the new task. It ensures that tasks are created and executed efficiently within the isolate thread, allowing for effective handling of concurrent operations and communication between threads.
  void _createFunction(IsolateMessageRequest event) {
    _confirmTask((int id) async {
      final content = event.payload as IsolateMessageResultFunction;
      return content.execute();
    });
  }

  @override
  void performObjectDiscard() {
    super.performObjectDiscard();
  }
}
