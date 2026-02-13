import 'dart:async';
import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/isolate/channels/isolator_channel.dart';
import 'package:maxi_thread/src/isolate/connections/isolate_message.dart';
import 'package:rxdart/rxdart.dart';

class IsolateTaskSender with DisposableMixin {
  final IsolatorChannel channel;
  final String threadName;

  final _confirmationMutex = Mutex();
  final _tasks = <_IsolateTaskInstance>[];

  Completer<Result<IsolateMessageStatus>>? _confirmationCompleter;

  IsolateTaskSender({required this.channel, required this.threadName}) {
    channel.stream.whereType<IsolateMessageStatus>().listen(_processMessage, onDone: () => dispose());
  }

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
  void performObjectDiscard() {
    _tasks.lambda((x) => x.dispose());
    _tasks.clear();
  }

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

class _IsolateTaskInstance<T> with DisposableMixin {
  final int id;

  final _completer = Completer<Result<T>>();
  late final List<Function> _interactiveFunctions;

  _IsolateTaskInstance({required this.id}) {
    _interactiveFunctions = InteractiveSystem.getAllSenders();
  }

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

  FutureResult<T> waitResult() => _completer.future;

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
  void performObjectDiscard() {
    if (!_completer.isCompleted) {
      _completer.complete(CancelationResult<T>());
    }
  }
}
