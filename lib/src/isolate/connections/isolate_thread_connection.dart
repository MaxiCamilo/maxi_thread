import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/isolate/channels/isolator_channel.dart';
import 'package:maxi_thread/src/isolate/connections/isolate_task_processor.dart';
import 'package:maxi_thread/src/isolate/connections/isolate_task_sender.dart';
import 'package:maxi_thread/src/isolate/isolated_thread.dart';
import 'package:maxi_thread/src/thread_connection.dart';
import 'package:maxi_thread/src/thread_singleton.dart';

class IsolateThreadConnection with DisposableMixin, LifecycleHub implements ThreadConnection {
  @override
  String name;

  @override
  int identifier;

  final IsolatorChannel channel;

  late final IsolateTaskSender taskSender;
  late final IsolateTaskProcessor taskProcessor;

  IsolateThreadConnection({this.name = '', this.identifier = 0, required this.channel}) {
    channel.onDispose.whenComplete(dispose);

    taskSender = IsolateTaskSender(channel: channel, threadName: name);
    taskProcessor = IsolateTaskProcessor(channel: channel, threadName: name);
  }

  FutureResult<void> obtaintThreadData() async {
    if (itWasDiscarded) {
      return CancelationResult();
    }

    final data = await execute(function: _sendData);
    if (data.itsFailure) {
      return data.cast();
    }

    identifier = data.content.$1;
    name = data.content.$2;
    return voidResult;
  }

  static (int, String) _sendData(InvocationParameters parameters) {
    final threadManager = threadSystem as IsolatedThread;
    return (threadManager.identifier, threadManager.name);
  }

  @override
  FutureResult<void> requestClosure() async {
    if (!itWasDiscarded) {
      dispose();
    }
    return voidResult;
  }

  @override
  Future<Result<T>> execute<T>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<T> Function(InvocationParameters para) function}) {
    return taskSender.execute(parameters: parameters, function: function);
  }

  @override
  Future<Result<T>> executeResult<T>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<T>> Function(InvocationParameters para) function}) {
    return taskSender.executeResult(parameters: parameters, function: function);
  }

  @override
  void performObjectDiscard() {
    super.performObjectDiscard();
    channel.dispose();
    taskSender.dispose();
    taskProcessor.dispose();
  }
}
