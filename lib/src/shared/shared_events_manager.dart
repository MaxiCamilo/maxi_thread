import 'package:maxi_framework/maxi_framework.dart';

class SharedEventsManager with DisposableMixin {
  final Map<String, List<Channel>> _eventsMap = {};

  Result<void> registerEvent<T>(String eventName, Channel<T, T> channel) {
    final receive = channel.getReceiver();

    if (receive.itsFailure) return receive.cast();

    receive.content.listen(
      (item) {
        _sendResult(eventName, channel, item);
      },
      onDone: () {
        if (itWasDiscarded) return;
        _channelClosed(eventName, channel);
      },
    );

    if (_eventsMap.containsKey(eventName)) {
      _eventsMap[eventName]!.add(channel);
    } else {
      _eventsMap[eventName] = [channel];
    }

    return voidResult;
  }

  void _sendResult<T>(String eventName, Channel<T, T> originChannel, T item) {
    if (itWasDiscarded) return;

    final list = _eventsMap[eventName];
    if (list == null) return;

    for (final channel in list) {
      if (channel == originChannel) continue;

      if (channel.senderType == T) {
        channel.sendItem(item).logIfFails(errorName: 'SharedEventsManager._sendResult -> Failed to send event item to channel');
      }
    }
  }

  @override
  void performObjectDiscard() {
    _eventsMap.values.lambda((x) => x.lambda((y) => y.dispose()));
    _eventsMap.clear();
  }

  void _channelClosed(String eventName, Channel channel) {
    if (itWasDiscarded) return;

    final list = _eventsMap[eventName];
    if (list == null) return;

    list.remove(channel);
    if (list.isEmpty) {
      _eventsMap.remove(eventName);
    }
  }
}
