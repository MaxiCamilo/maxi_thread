import 'dart:async';
import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/isolate/isolated_thread.dart';
import 'package:maxi_thread/src/thread_connection.dart';
import 'package:maxi_thread/src/thread_singleton.dart';

class IsolateOriginChannel<R, S> with DisposableMixin {
  final int channelId;
  final Channel<R, S> channel;
  final ThreadConnection origin;

  IsolateOriginChannel({required this.channelId, required this.channel, required this.origin}) {
    final channelResult = channel.getReceiver();
    if (channelResult.itsFailure) {
      throw channelResult.error;
    }

    channelResult.content.listen(_sendResult, onError: _sendError, onDone: dispose);
  }
  void _sendResult(R event) {
    origin.executeResult(function: _notifyItem, parameters: InvocationParameters.list([channelId, event])).logIfFails(errorName: 'IsolateOriginChannel -> _sendResult: Failed to send item to origin');
  }

  static FutureOr<Result<void>> _notifyItem(InvocationParameters para) {
    return threadSystem
        .dynamicCastResult<IsolatedThread>(errorMessage: const FixedOration(message: 'Failed to cast thread system to IsolatedThread'))
        .onCorrect((x) => x.channelManager.notifyItem(channelId: para.first<int>(), item: para.second()));
  }

  void _sendError(Object error, StackTrace stackTrace) {
    origin.executeResult(function: _notifyError, parameters: InvocationParameters.list([channelId, error, stackTrace])).logIfFails(errorName: 'IsolateOriginChannel -> _sendError: Failed to send error to origin');
  }

  static FutureOr<Result<void>> _notifyError(InvocationParameters para) {
    return threadSystem
        .dynamicCastResult<IsolatedThread>(errorMessage: const FixedOration(message: 'Failed to cast thread system to IsolatedThread'))
        .onCorrect((x) => x.channelManager.notifyError(channelId: para.first<int>(), error: para.second(), stackTrace: para.third<StackTrace>()));
  }

  void receiveItem(dynamic item) {
    if (item is S) {
      channel.sendItem(item).logIfFails(errorName: 'IsolateOriginChannel -> receiveItem: SendItem failed');
    } else {
      log('IsolateOriginChannel -> receiveItem: Received item of type ${item.runtimeType} which is not of expected type ${S.toString()}', name: 'IsolateOriginChannel', level: 900);
    }
  }

  @override
  void performObjectDiscard() {
    if (channel.itWasDiscarded) {
      origin
          .executeResult(function: _notifyEndChannel, parameters: InvocationParameters.only(channelId))
          .logIfFails(errorName: 'IsolateOriginChannel -> performObjectDiscard: Failed to notify origin about channel discard');
    } else {
      channel.dispose();
    }
  }

  static FutureOr<Result<void>> _notifyEndChannel(InvocationParameters para) {
    return threadSystem
        .dynamicCastResult<IsolatedThread>(errorMessage: const FixedOration(message: 'Failed to cast thread system to IsolatedThread'))
        .onCorrect((x) => ResultValue(content: x.channelManager.notifyExternalChannelDiscard(channelId: para.first<int>())));
  }
}
