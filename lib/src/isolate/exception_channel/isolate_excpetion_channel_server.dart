import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/isolate/server/isolated_thread_server.dart';

class IsolateExcpetionChannelServer with DisposableMixin, LifecycleHub implements Channel<(dynamic, StackTrace), (dynamic, StackTrace)> {
  final IsolatedThreadServer threadServer;

  late final StreamController<(dynamic, StackTrace)> _serverChannel;
  late final MasterChannel<(dynamic, StackTrace), (dynamic, StackTrace)> _clientsChannel;

  final _clientsMap = <int, Channel<(dynamic, StackTrace), (dynamic, StackTrace)>>{};

  IsolateExcpetionChannelServer({required this.threadServer}) {
    _serverChannel = joinStreamController(StreamController<(dynamic, StackTrace)>.broadcast());
    _clientsChannel = joinDisposableObject(MasterChannel<(dynamic, StackTrace), (dynamic, StackTrace)>());
  }

  @override
  Result<Stream<(dynamic, StackTrace)>> getReceiver() {
    final itsDiscard = failIfItsDiscarded();
    if (itsDiscard.itsFailure) {
      return itsDiscard.cast();
    }

    return _serverChannel.stream.asResultValue();
  }

  @override
  Result<void> sendItem((dynamic, StackTrace) item) {
    final itsDiscard = failIfItsDiscarded();
    if (itsDiscard.itsFailure) {
      return itsDiscard.cast();
    }

    _serverChannel.add(item);
    _clientsChannel.sendItem(item);

    return voidResult;
  }

  Result<void> clientSentException({required int threadID, required (dynamic, StackTrace) exception}) {
    final itsDiscard = failIfItsDiscarded();
    if (itsDiscard.itsFailure) {
      return itsDiscard.cast();
    }

    _serverChannel.add(exception);
    final threadID = ThreadConnection.threadZone.identifier;
    _clientsMap.where((key, value) => key != threadID).forEach((key, value) => value.sendItem(exception));

    return voidResult;
  }

  FutureResult<void> connectClient(Channel<(dynamic, StackTrace), (dynamic, StackTrace)> channel) async {
    final threadID = ThreadConnection.threadZone.identifier;
    _clientsMap[threadID] = channel;

    return channel.getReceiver().onCorrect<void>((stream) {
      stream.listen(
        (item) {
          clientSentException(threadID: threadID, exception: item);
        },
        onDone: () {
          _clientsMap.remove(threadID);
        },
      );
      return voidResult;
    });
  }
}
