import 'dart:async';
import 'dart:isolate';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/isolated/channels/isolator_channel.dart';

class IsolatorChannelEndPoint with DisposableMixin implements IsolatorChannel {
  final SendPort sendPoint;

  late final ReceivePort receivePoint;

  late final StreamController _streamController;

  @override
  Stream get stream => _streamController.stream;

  IsolatorChannelEndPoint({required this.sendPoint}) {
    _streamController = StreamController.broadcast();
    receivePoint = ReceivePort();
    receivePoint.listen(_processDataReceived, onDone: dispose);

    sendPoint.send(receivePoint.sendPort);
  }

  @override
  void performObjectDiscard() {
    receivePoint.close();
    _streamController.close();
  }

  void _processDataReceived(dynamic message) {
    _streamController.add(message);
  }

  @override
  Result<void> send(dynamic item) {
    try {
      sendPoint.send(item);
      return voidResult;
    } catch (ex, st) {
      return ExceptionResult(exception: ex, stackTrace: st);
    }
  }

  @override
  Future<Result<void>> waitInitialization({required Duration timeout}) async {
    if (itWasDiscarded) {
      return NegativeResult.controller(
        code: ErrorCode.discontinuedFunctionality,
        message: FixedOration(message: 'The channel was already close'),
      );
    }

    return voidResult;
  }
}
