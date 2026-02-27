import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/isolate/isolated_thread.dart';

class IsolateReferenceChannel<R, S> with DisposableMixin, LifecycleHub implements Channel<R, S> {
  final int channelId;
  final ThreadConnection origin;
  late final StreamController<R> _streamController;

  IsolateReferenceChannel({required this.channelId, required this.origin}) {
    createDependency(origin).exceptionIfFails(detail: 'Failed to create dependency for IsolateReferenceChannel');
    _streamController = joinStreamController(StreamController<R>.broadcast());
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

    origin.executeResult(parameters: InvocationParameters.list([channelId, item]), function: _sendItemToOrigin).logIfFails(errorName: 'IsolateReferenceChannel -> sendItem: Failed to send item to origin');

    return voidResult;
  }

  static FutureOr<Result<void>> _sendItemToOrigin(InvocationParameters para) async {
    final channelID = para.first<int>();
    final item = para.second();

    final isolateThread = threadSystem.dynamicCastResult<IsolatedThread>(errorMessage: const FixedOration(message: 'Failed to cast thread system to IsolatedThread')).select((x) => x.channelManager);
    if (isolateThread.itsFailure) {
      return isolateThread.cast();
    }
    return isolateThread.content.searchOriginChannel(channelID).onCorrectLambda((x) => x.receiveExternalItem(item)).ignoreContent();
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

    return isolateThread.content.searchOriginChannel(channelID).onCorrectLambda((x) => x.dispose()).ignoreContent();
  }
}
