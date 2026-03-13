import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/isolate/exception_channel/isolate_excpetion_channel_server.dart';

class IsolateExceptionChannelClient with DisposableMixin, AsynchronouslyInitializedMixin, LifecycleHub implements Channel<(dynamic, StackTrace), (dynamic, StackTrace)> {
  late final Channel<(dynamic, StackTrace), (dynamic, StackTrace)> _serverChannel;
  late final int threadID;

  late final StreamController<(dynamic, StackTrace)> _streamController;

  @override
  Future<Result<void>> performInitialize() async {
    threadID = threadSystem.identifier;

    final newChannelResult = await threadSystem.serverConnection.buildChannel<(dynamic, StackTrace), (dynamic, StackTrace)>(function: _buildChannelOnServer);
    if (newChannelResult.itsFailure) {
      return newChannelResult.cast();
    }

    _serverChannel = newChannelResult.content;
    _streamController = joinStreamController(StreamController<(dynamic, StackTrace)>.broadcast());

    final receiverResult = _serverChannel.getReceiver();
    if(receiverResult.itsFailure){
      return receiverResult.cast();
    }

    receiverResult.content.listen(
      (item) {
        _streamController.add(item);
      },
      onDone: () {
        dispose();
      },
    );

    return voidResult;
  }

  static FutureResult<void> _buildChannelOnServer(Channel<(dynamic, StackTrace), (dynamic, StackTrace)> channel, InvocationParameters para) async {
    final serverThread = (appManager.exceptionChannel).dynamicCastResult<IsolateExcpetionChannelServer>();
    if (serverThread.itsFailure) {
      return serverThread.cast();
    }

    final connectionResult = await serverThread.content.connectClient(channel);
    if (connectionResult.itsFailure) {
      return connectionResult.cast();
    }

    await channel.onDispose;
    return voidResult;
  }

  @override
  Result<Stream<(dynamic, StackTrace)>> getReceiver() {
    final itsDiscard = failIfItsDiscarded();
    if (itsDiscard.itsFailure) {
      return itsDiscard.cast();
    }

    return _streamController.stream.asResultValue();
  }

  @override
  Result<void> sendItem((dynamic, StackTrace) item) {
    final itsDiscard = failIfItsDiscarded();
    if (itsDiscard.itsFailure) {
      return itsDiscard.cast();
    }

    return _serverChannel.sendItem(item);
  }
}
