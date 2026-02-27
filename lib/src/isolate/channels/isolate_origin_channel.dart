import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/isolate/isolated_thread.dart';

class IsolateOriginChannel<R, S> with DisposableMixin, LifecycleHub implements Channel<R, S> {
  final int channelId;
  final ThreadConnection origin;
  final FutureOr<Result<void>> Function(Channel<R, S>, InvocationParameters) function;
  final InvocationParameters parameters;

  late final StreamController<R> _streamController;
  late final AsyncExecutor _executor;

  IsolateOriginChannel({required this.channelId, required this.origin, required this.function, required this.parameters}) {
    createDependency(origin).exceptionIfFails(detail: 'Failed to create dependency for IsolateOriginChannel');
    _streamController = joinStreamController(StreamController<R>.broadcast());
    _executor = joinDisposableObject(AsyncExecutor<void>(function: _executeFunction));
    _executor.waitResult().onNegativeFuture(_sendFinishError).whenComplete(() => dispose());
  }

  Future<Result<dynamic>> _sendFinishError(ErrorData error) async {
    await origin
        .executeResult(
          parameters: InvocationParameters.list([channelId, NegativeResult(error: error)]),
          function: _sendItemToReference,
        )
        .logIfFails(errorName: 'IsolateOriginChannel -> _sendFinishError: Failed to send finish error to reference');

    return voidResult;
  }

  Future<Result<void>> _executeFunction() async {
    await Future.delayed(Duration.zero);
    await Future.delayed(Duration.zero);
    return await function(this, parameters);
  }

  @override
  Result<Stream<R>> getReceiver() {
    if (itWasDiscarded) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: const FixedOration(message: 'The channel has been discarded, so it cannot receive items'),
      );
    }

    return ResultValue(content: _streamController.stream);
  }

  @override
  Result<void> sendItem(S item) {
    if (itWasDiscarded) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: const FixedOration(message: 'The channel has been discarded, so it cannot send items'),
      );
    }

    origin
        .executeResult(parameters: InvocationParameters.list([channelId, item]), function: _sendItemToReference)
        .logIfFails(errorName: '[$channelId]IsolateOriginChannel (Thread ${threadSystem.identifier} to ${origin.identifier}) -> sendItem: Failed to send item to reference');

    return voidResult;
  }

  static FutureOr<Result<void>> _sendItemToReference(InvocationParameters para) async {
    final channelID = para.first<int>();
    final item = para.second();

    final isolateThread = threadSystem.dynamicCastResult<IsolatedThread>(errorMessage: const FixedOration(message: 'Failed to cast thread system to IsolatedThread')).select((x) => x.channelManager);
    if (isolateThread.itsFailure) {
      return isolateThread.cast();
    }
    return isolateThread.content
        .searchReferenceChannel(channelID)
        .onCorrectLambda((x) => x.receiveExternalItem(item))
        .ignoreContent()
        .logIfFails(
          errorName:
              '[$channelID]IsolateOriginChannel (Receive from ${ThreadConnection.threadZone.identifier} for ${threadSystem.dynamicCastResult<IsolatedThread>().content.identifier}) -> _sendItemToReference: Failed to send item to reference channel',
        );
  }

  Result<void> receiveExternalItem(dynamic item) {
    if (item is R) {
      if (!itWasDiscarded) {
        _streamController.add(item);
      }
      return voidResult;
    } else if (item is NegativeResult) {
      if (!itWasDiscarded) {
        _streamController.addError(item);
      }
      return voidResult;
    } else {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'The received item is not of the expected type for this channel (receive only %1)', textParts: [R]),
      );
    }
  }

  @override
  void performObjectDiscard() {
    super.performObjectDiscard();

    origin.executeResult(parameters: InvocationParameters.only(channelId), function: _declareFinished);
  }

  static Future<Result<void>> _declareFinished(InvocationParameters para) async {
    final channelID = para.first<int>();

    final isolateThread = threadSystem.dynamicCastResult<IsolatedThread>(errorMessage: const FixedOration(message: 'Failed to cast thread system to IsolatedThread')).select((x) => x.channelManager);
    if (isolateThread.itsFailure) {
      return isolateThread.cast();
    }

    return isolateThread.content.searchReferenceChannel(channelID).onCorrectLambda((x) => x.dispose()).ignoreContent().logIfFails(errorName: 'IsolateOriginChannel -> _declareFinished: Failed to declare finished');
  }
}
