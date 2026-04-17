import 'dart:async';
import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/isolate/communication/isolator_channel.dart';
import 'package:maxi_thread/src/isolate/connections/isolate_message.dart';
import 'package:maxi_thread/src/thread_connection.dart';
import 'package:maxi_thread/src/thread_manager.dart';
import 'package:maxi_thread/src/thread_singleton.dart';
import 'package:rxdart/rxdart.dart';

/// Processes and manages task execution within an isolate thread.
///
/// Handles incoming task requests through an [IsolatorChannel], executes them asynchronously,
/// and communicates results back to the sender. Manages concurrent task execution, handles task
/// cancellation, and provides lifecycle management through disposal mechanisms. Each task is
/// assigned a unique ID for tracking and communication purposes.
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

  /// Confirms and executes a task by assigning it a unique ID, sending a confirmation message,
  /// executing the provided function, and communicating the result back through the channel.
  /// Manages the task lifecycle including disposal and error handling.
  Future<void> _confirmTask(FutureOr<Result> Function(int id) function) async {
    final id = _lastTaskId;
    _lastTaskId += 1;
    final sendConfirmationResult = channel.send(IsolateMessageStatus(type: IsolateMessageStatusType.confirmation, id: id, payload: null));
    if (sendConfirmationResult.itsFailure) {
      log('[IsolateTaskProcessor] Failed to send a confirmation message for task with id $id in thread $threadName. Error: $sendConfirmationResult');
      return;
    }

    late final AsyncExecutor task;

    task = AsyncExecutor(
      connectToZone: false,
      function: () {
        _programmerInteractiveMessages(id);
        return function(id);
      },
    );
    lifecycleScope.joinDisposableObject(task);

    _currentTask[id] = task;
    task.onDispose.whenComplete(() => _currentTask.remove(id));

    final result = await task.waitResult(zoneValues: {ThreadManager.kThreadManagerZone: threadSystem, ThreadConnection.kThreadConnectionZone: threadConnection});
    final sendResult = channel.send(IsolateMessageStatus(type: IsolateMessageStatusType.executeResult, id: id, payload: result));
    if (sendResult.itsFailure) {
      log('[IsolateTaskProcessor] Failed to send an execution result message for task with id $id in thread $threadName. Error: $sendResult');
      channel
          .send(
            IsolateMessageStatus(
              type: IsolateMessageStatusType.executeResult,
              id: id,
              payload: NegativeResult.controller(
                code: ErrorCode.wrongType,
                message: FlexibleOration(message: 'Failed to send the result of a task between threads, it appears to be a native object', textParts: [result.runtimeType.toString()]),
              ),
            ),
          )
          .logIfFails(errorName: 'IsolateTaskProcessor -> _confirmTask: Failed to send negative result message');
      return;
    }
  }

  /// Routes incoming task requests to the appropriate handler based on the request type.
  ///
  /// Processes [IsolateMessageRequest] events by switching on the request type:
  /// - [IsolateMessageRequestType.createFunction]: Creates and executes a new task function
  /// - [IsolateMessageRequestType.message]: Processes a message for an existing task
  /// - [IsolateMessageRequestType.cancel]: Cancels the task with the specified ID
  void _processRequest(IsolateMessageRequest event) {
    switch (event.type) {
      case IsolateMessageRequestType.createFunction:
        _createFunction(event);
        break;

      case IsolateMessageRequestType.cancel:
        _currentTask[event.id]?.dispose();
        break;
      case IsolateMessageRequestType.message:
        _currentTask[event.id]?.sendMessage(value: event.payload, payload: threadConnection);
        break;
    }
  }

  /// Extracts the function from the request payload and executes it as a confirmed task.
  ///
  /// Unwraps the [IsolateMessageResultFunction] from the event payload and passes it to
  /// [_confirmTask] for execution with proper ID assignment, tracking, and result communication.
  void _createFunction(IsolateMessageRequest event) {
    _confirmTask((int id) async {
      final content = event.payload as IsolateMessageResultFunction;
      return content.execute();
    });
  }

  void _programmerInteractiveMessages(int id) {
    InteractiveSystem.receiveValues(filter: (item, payload) => payload != threadConnection).selectVoid((stream) {
      stream.listen((item) {
        channel
            .send(IsolateMessageStatus(type: IsolateMessageStatusType.message, id: id, payload: item))
            .logIfFails(errorName: 'IsolateTaskProcessor -> _programmerInteractiveMessages: Failed to send an interactive message from the programmer interactive system');
      });
    });
  }

  @override
  void performObjectDiscard() {}
}
