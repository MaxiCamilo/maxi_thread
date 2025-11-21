import 'dart:async';
import 'dart:developer';
import 'dart:isolate';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/isolated/channels/isolator_channel.dart';

class IsolatorChannelInitiationPoint with DisposableMixin implements IsolatorChannel {
  late final ReceivePort receivePort;

  SendPort? _sender;

  SendPort get output => receivePort.sendPort;

  late final StreamController _streamController;

  @override
  Stream get stream => _streamController.stream;

  Completer<bool>? _confirmationWaiter;

  IsolatorChannelInitiationPoint() {
    receivePort = ReceivePort();
    receivePort.listen(_processDataReceived, onDone: dispose);

    _streamController = StreamController.broadcast();
  }

  @override
  void performObjectDiscard() {
    receivePort.close();
    _streamController.close();
    _confirmationWaiter?.complete(false);
    _confirmationWaiter = null;
  }

  @override
  Future<Result<void>> waitInitialization({required Duration timeout}) async {
    if (itWasDiscarded) {
      return NegativeResult.controller(
        code: ErrorCode.discontinuedFunctionality,
        message: FixedOration(message: 'The channel was already close'),
      );
    }

    if (_sender != null) return voidResult;

    _confirmationWaiter ??= Completer<bool>();
    return _confirmationWaiter!.future
        .toFutureResult()
        .timeout(
          timeout,
          onTimeout: () => NegativeResult.controller(
            code: ErrorCode.timeout,
            message: FixedOration(message: 'The channel initialization has timed out'),
          ),
        )
        .onCorrectFuture((confirmed) {
          if (confirmed) {
            return voidResult;
          } else {
            return NegativeResult.controller(
              code: ErrorCode.timeout,
              message: FixedOration(message: 'Could not initialize thread channel'),
            );
          }
        });
  }

  Future<bool> waitConfirmation() async {
    if (itWasDiscarded) return false;
    if (_sender != null) return true;

    _confirmationWaiter ??= Completer<bool>();
    return _confirmationWaiter!.future;
  }

  void _processDataReceived(dynamic message) {
    if (_sender == null) {
      if (message is SendPort) {
        _sender = message;
        _confirmationWaiter?.complete(true);
        _confirmationWaiter = null;
      } else {
        log('[IsolatorChannelInitiationPoint] The thread has not yet sent its SendPort!');
      }

      return;
    }

    if (_streamController.isClosed) {
      log('[IsolatorChannelInitiationPoint] This point is closed!');
    } else {
      _streamController.add(message);
    }
  }

  @override
  Result<void> send(dynamic item) {
    if (_sender == null) {
      log('[IsolatorChannelInitiationPoint] The thread has not yet sent its SendPort!');
      return NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: FixedOration(message: 'The thread has not yet sent its SendPort'),
      );
    }

    try {
      _sender!.send(item);
      return voidResult;
    } catch (ex, st) {
      return ExceptionResult(exception: ex, stackTrace: st);
    }
  }
}
