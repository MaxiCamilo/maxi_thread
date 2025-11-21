import 'dart:async';
import 'dart:developer';
import 'dart:isolate';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/isolated/channels/isolator_channel.dart';
import 'package:maxi_thread/src/isolated/connections/isolated_thread_executor.dart';
import 'package:maxi_thread/src/isolated/connections/isolated_thread_requester.dart';
import 'package:maxi_thread/src/isolated/isolate_stream_manager.dart';
import 'package:maxi_thread/src/isolated/isolate_thread_instance.dart';
import 'package:maxi_thread/src/isolated/messages/isolated_thread_message.dart';

class IsolatedThreadConnection with DisposableMixin implements ThreadInvocator, IsolatedThread {
  final IsolatorChannel channel;
  final Map<dynamic, dynamic> zoneValues;
  final IsolateThreadInstance instance;

  late final IsolatedThreadExecutor _executor;
  late final IsolatedThreadRequester _requester;

  @override
  IsolateStreamManager get streamManager => instance.streamManager;

  @override
  Stream<T> executeStream<T>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Result<Stream<T>>> Function(InvocationParameters para) function}) async* {
    if (itWasDiscarded) {
      throw NegativeResult.controller(
        code: ErrorCode.discontinuedFunctionality,
        message: FixedOration(message: 'The thread was discarded'),
      ).error;
    }

    final stream = await streamManager.executeStream<T>(origin: this, parameters: parameters, function: function);

    if (stream.itsFailure) throw stream;
    yield* stream.content;
  }

  IsolatedThreadConnection({required this.instance, required this.channel, required this.zoneValues}) {
    channel.stream.listen(_processPackage, onDone: dispose);

    _executor = IsolatedThreadExecutor(channel: channel, instance: instance, zoneValues: zoneValues, invocator: this);
    _requester = IsolatedThreadRequester(channel: channel);

    onDispose.whenComplete(channel.dispose);
  }

  @override
  Future<Result<T>> execute<T>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<T> Function(InvocationParameters para) function}) {
    return _requester.execute<T>(function: function, parameters: parameters);
  }

  @override
  Future<Result<T>> executeResult<T>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Result<T>> Function(InvocationParameters para) function}) {
    return _requester.executeResult<T>(function: function, parameters: parameters);
  }

  @override
  Future<Result<void>> closeThread() => execute(function: _closeThread);
  static Future<Result<void>> _closeThread(InvocationParameters para) async {
    final threadInstance = ThreadInstance.getIsolatedInstance();
    if (threadInstance.itsFailure) return threadInstance.cast<void>();

    return await threadInstance.whenFutureCast<IsolatedThread, void>((x) => x.closeThread());
  }

  @override
  Future<Result<SendPort>> getNewSendPortFromThread() => executeResult(function: _getNewSendPortFromThread);
  static Future<Result<SendPort>> _getNewSendPortFromThread(InvocationParameters para) async {
    final threadInstance = ThreadInstance.getIsolatedInstance();
    if (threadInstance.itsFailure) return threadInstance.cast<SendPort>();
    return await threadInstance.whenFutureCast<IsolatedThread, SendPort>((x) => x.getNewSendPortFromThread());
  }

  @override
  Future<Result<T>> executeFunctionality<T>({required Functionality<T> functionality}) {
    return executeResult<T>(function: _executeFunctionalityFromThread<T>, parameters: InvocationParameters.only(functionality));
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

  @override
  Future<Result<ThreadInvocator>> getInvocatorByID({required int identifier}) {
    // TODO: implement getInvocatorByID
    throw UnimplementedError();
  }
}
