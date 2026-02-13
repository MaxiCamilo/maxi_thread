import 'dart:async';
import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/isolate/channels/isolator_channel.dart';
import 'package:maxi_thread/src/isolate/connections/isolate_message.dart';
import 'package:rxdart/rxdart.dart';

class IsolateTaskProcessor with DisposableMixin, LifecycleHub {
  final IsolatorChannel channel;
  final String threadName;

  final _currentTask = <int, AsyncExecutor>{};

  int _lastTaskId = 1;

  IsolateTaskProcessor({required this.channel, required this.threadName}) {
    channel.stream.whereType<IsolateMessageRequest>().listen(_processRequest, onDone: dispose);
  }

  Future<void> _confirmTask(FutureOr<Result> Function(int id) function) async {
    final id = _lastTaskId;
    final sendConfirmationResult = channel.send(IsolateMessageStatus(type: IsolateMessageStatusType.confirmation, id: id, payload: null));
    if (sendConfirmationResult.itsFailure) {
      log('[IsolateTaskProcessor] Failed to send a confirmation message for task with id $id in thread $threadName. Error: $sendConfirmationResult');
      return;
    }
    _lastTaskId += 1;

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

    final result = await task.waitResult();
    final sendResult = channel.send(IsolateMessageStatus(type: IsolateMessageStatusType.executeResult, id: id, payload: result));
    if (sendResult.itsFailure) {
      log('[IsolateTaskProcessor] Failed to send an execution result message for task with id $id in thread $threadName. Error: $sendResult');
      return;
    }
  }

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
