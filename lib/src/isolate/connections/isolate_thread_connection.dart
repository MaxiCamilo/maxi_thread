import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/isolate/communication/isolator_channel.dart';
import 'package:maxi_thread/src/isolate/connections/isolate_task_processor.dart';
import 'package:maxi_thread/src/isolate/connections/isolate_task_sender.dart';
import 'package:maxi_thread/src/isolate/isolated_thread.dart';
import 'package:maxi_thread/src/thread_connection.dart';
import 'package:maxi_thread/src/thread_singleton.dart';

/// Represents a connection to an isolate thread, allowing for the execution of tasks and management of the thread's lifecycle. The `IsolateThreadConnection` class provides methods for executing functions in the isolate thread, requesting closure of the thread, and handling the disposal of resources associated with the connection. It manages communication with the isolate thread through an `IsolatorChannel`, and it uses `IsolateTaskSender` and `IsolateTaskProcessor` to handle task execution and processing. This class is designed to facilitate effective communication and task management in an isolated environment, allowing for concurrent processing and efficient resource management in a multi-threaded application.
class IsolateThreadConnection with DisposableMixin, LifecycleHub implements ThreadConnection {
  @override
  String name;

  @override
  int identifier;

  final IsolatorChannel channel;

  /// The [taskSender] is responsible for sending task requests to the isolate thread and managing the communication of task-related messages, while the [taskProcessor] handles the processing of incoming task requests and the execution of corresponding functions within the isolate thread. These components work together to facilitate effective task management and communication between the main thread and the isolate thread, allowing for concurrent processing and efficient handling of tasks in an isolated environment.
  late final IsolateTaskSender taskSender;

  /// The [taskProcessor] is responsible for processing incoming task requests and executing corresponding functions within the isolate thread, while the [taskSender] manages the sending of task requests to the isolate thread and the communication of task-related messages. These components work together to facilitate effective task management and communication between the main thread and the isolate thread, allowing for concurrent processing and efficient handling of tasks in an isolated environment.
  late final IsolateTaskProcessor taskProcessor;

  IsolateThreadConnection({this.name = '', this.identifier = 0, required this.channel}) {
    channel.onDispose.whenComplete(dispose);

    taskSender = IsolateTaskSender(channel: channel, threadName: name);
    taskProcessor = IsolateTaskProcessor(channel: channel, threadName: name, threadConnection: this);
  }

  /// Obtains the thread data, including the identifier and name, by executing a function in the isolate thread. If the connection has been discarded, it returns a cancellation result. If there is an error during execution, it returns the error wrapped in a `Result` type. If the data is obtained successfully, it updates the `identifier` and `name` properties of the connection and returns a void result. This method allows for effective retrieval of thread information while handling potential errors and ensuring that operations are not performed on a discarded connection.
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

  /// A static function that retrieves the thread data, including the identifier and name, from the isolate thread. This function is executed in the isolate thread and returns a tuple containing the thread's identifier and name. The function accesses the thread manager from the thread system and retrieves the necessary information to provide insights into the thread's identity, allowing for effective communication and management of threads in an isolated environment.
  static (int, String) _sendData(InvocationParameters parameters) {
    final threadManager = threadSystem as IsolatedThread;
    return (threadManager.identifier, threadManager.name);
  }

  @override
  /// Requests the closure of the isolate thread by executing a closure request function in the isolate thread. If the connection has already been discarded, it returns a void result. If there is an error during execution, it logs the error and returns a void result. If the closure request is executed successfully, it returns a void result. This method allows for effective management of the thread's lifecycle by enabling the main thread to request the closure of the isolate thread while handling potential errors and ensuring that operations are not performed on a discarded connection.
  FutureResult<void> requestClosure() async {
    if (itWasDiscarded) {
      return voidResult;
    }

    await execute(function: _requestClosure).logIfFails(errorName: 'IsolateThreadConnection -> RequestClosure: Failed to execute closure request');

    //dispose();
    return voidResult;
  }

  /// A static function that requests the closure of the isolate thread by accessing the thread manager and invoking its dispose method. This function is executed in the isolate thread and allows for effective management of the thread's lifecycle by enabling the thread to respond to closure requests from the main thread, ensuring that resources are properly cleaned up and that the thread is terminated gracefully when requested.
  static Future<void> _requestClosure(InvocationParameters parameters) async {
    final threadManager = threadSystem as IsolatedThread;
    threadManager.dispose();
  }

  @override
  /// Executes a function in the isolate thread with the provided parameters and returns the result wrapped in a `Result` type. If the connection has been discarded, it returns a cancellation result. If there is an error during execution, it returns the error wrapped in a `Result` type. If the function is executed successfully, it returns the result wrapped in a `Result` type. This method allows for effective execution of functions in the isolate thread while handling potential errors and ensuring that operations are not performed on a discarded connection.
  Future<Result<T>> execute<T>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<T> Function(InvocationParameters para) function}) {
    return taskSender.execute(parameters: parameters, function: function);
  }

  @override
  /// Executes a function in the isolate thread with the provided parameters and returns the result wrapped in a `Result` type. If the connection has been discarded, it returns a cancellation result. If there is an error during execution, it returns the error wrapped in a `Result` type. If the function is executed successfully, it returns the result wrapped in a `Result` type. This method allows for effective execution of functions in the isolate thread while handling potential errors and ensuring that operations are not performed on a discarded connection.
  Future<Result<T>> executeResult<T>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<T>> Function(InvocationParameters para) function}) {
    return taskSender.executeResult(parameters: parameters, function: function);
  }

  @override
  /// Disposes of the connection by disposing of the channel, task sender, and task processor. This ensures that all resources associated with the connection are properly cleaned up when the connection is discarded, preventing memory leaks and ensuring that ongoing tasks are appropriately terminated in response to the disposal of the connection.
  void performObjectDiscard() {
    super.performObjectDiscard();
    channel.dispose();
    taskSender.dispose();
    taskProcessor.dispose();
  }

  @override
  FutureResult<Channel<S, R>> buildChannel<R, S>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<Channel<R, S>>> Function(InvocationParameters para) function}) async {
    return threadSystem.dynamicCastResult<IsolatedThread>().onCorrectFuture((x) => x.channelManager.executeRequest<R, S>(parameters: parameters, function: function, connection: this));
  }
}
