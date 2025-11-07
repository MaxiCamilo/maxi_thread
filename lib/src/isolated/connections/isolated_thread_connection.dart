import 'dart:async';
import 'dart:developer';
import 'dart:isolate';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/isolated/channels/isolator_channel.dart';
import 'package:maxi_thread/src/isolated/connections/isolated_thread_executor.dart';
import 'package:maxi_thread/src/isolated/connections/isolated_thread_requester.dart';
import 'package:maxi_thread/src/isolated/messages/isolated_thread_message.dart';

class IsolatedThreadConnection with DisposableMixin implements ThreadInvocator, IsolatedThread {
  final IsolatorChannel channel;

  late final IsolatedThreadExecutor _executor;
  late final IsolatedThreadRequester _requester;

  IsolatedThreadConnection({required this.channel}) {
    channel.stream.listen(_processPackage, onDone: dispose);

    _executor = IsolatedThreadExecutor(channel: channel);
    _requester = IsolatedThreadRequester(channel: channel);

    onDispose.whenComplete(channel.dispose);
  }

  @override
  Future<Result<T>> execute<T>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<T> Function(InvocationParameters para) function}) {
    return _requester.execute<void, T>(function: function, parameters: parameters);
  }

  @override
  Future<Result<T>> executeResult<T>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Result<T>> Function(InvocationParameters para) function}) {
    return _requester.executeResult<void, T>(function: function, parameters: parameters);
  }

  @override
  Future<Result<T>> executeInteractively<I, T>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<T> Function(InvocationParameters para) function, required void Function(I p1) onItem}) {
    return _requester.execute<I, T>(function: function, parameters: parameters, onItem: onItem);
  }

  @override
  Future<Result<T>> executeInteractivelyResult<I, T>({
    InvocationParameters parameters = InvocationParameters.emptry,
    required FutureOr<Result<T>> Function(InvocationParameters para) function,
    required void Function(I p1) onItem,
  }) {
    return _requester.executeResult<I, T>(function: function, parameters: parameters, onItem: onItem);
  }

  @override
  Stream<T> executeStream<T>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Stream<T>> Function(InvocationParameters para) function}) {
    // TODO: implement executeStream
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> closeThread() => execute(function: _closeThread);
  static Future<void> _closeThread(InvocationParameters para) {
    return (ThreadSingleton.instance as IsolatedThread).closeThread();
  }

  @override
  Future<Result<SendPort>> getNewSendPortFromThread() => executeResult(function: _getNewSendPortFromThread);
  static Future<Result<SendPort>> _getNewSendPortFromThread(InvocationParameters para) {
    return (ThreadSingleton.instance as IsolatedThread).getNewSendPortFromThread();
  }

  @override
  Future<Result<T>> executeFunctionality<T>({required Functionality<T> functionality, required void Function(Oration text) onText}) {
    return executeInteractivelyResult<Oration, T>(function: _executeFunctionalityFromThread<T>, parameters: InvocationParameters.only(functionality), onItem: onText);
  }

  static Future<Result<T>> _executeFunctionalityFromThread<T>(InvocationParameters para) async {
    final functionality = para.firts<Functionality<T>>().separateExecution();
    functionality.connectToHeart();

    return functionality.waitResult();
  }

  @override
  void performObjectDiscard() {}

  void _processPackage(dynamic event) {
    if (event is IsolatedThreadMessage) {
      switch (event.type) {
        case IsolatedThreadMessageType.interactionValue:
          _requester.processItemInteraction(event.identifier, event.content);
          break;
        case IsolatedThreadMessageType.newFunction:
          _executor.createFunction(event.content);
          break;
        case IsolatedThreadMessageType.result:
          _requester.processResult(event.identifier, event.content);
          break;
        case IsolatedThreadMessageType.confirmation:
          _requester.confirmNewExecution(event.identifier);
          break;
        case IsolatedThreadMessageType.cancel:
          _executor.cancelFunction(event.identifier);
          break;

        case IsolatedThreadMessageType.closed:
          dispose();
          break;
      }
    } else {
      log('[IsolatedThreadConnection] The thread sent an object of type ${event.runtimeType}, but expected a IsolatedThreadMessage');
    }
  }
}
