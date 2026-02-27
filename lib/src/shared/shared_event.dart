import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/shared/shared_service.dart';

class SharedEvent<T> with AsynchronouslyInitializedMixin implements Channel<T, T> {
  final String name;

  late Channel<T, T> _channel;

  SharedEvent({required this.name});

  @override
  Future<Result<void>> performInitialize() async {
    final newChannelResult = await SharedService.connection().onCorrectFuture((x) => x.buildChannel(parameters: InvocationParameters.only(name), function: _createChannel<T>));
    if (newChannelResult.itsFailure) return newChannelResult.cast();

    _channel = newChannelResult.content;
    return voidResult;
  }

  static FutureResult<void> _createChannel<T>(SharedService service, Channel<T, T> channel, InvocationParameters parameters) async {
    final regResult = service.eventManager.registerEvent<T>(parameters.first<String>(), channel);
    if (regResult.itsFailure) {
      channel.dispose();
      return regResult.cast();
    }

    await channel.onDispose;
    return voidResult;
  }

  @override
  Result<Stream<T>> getReceiver() {
    Stream<T> func() async* {
      final initRes = await initialize();
      if (initRes.itsFailure) throw initRes;

      final streamRes = _channel.getReceiver();
      if (streamRes.itsFailure) throw streamRes;
      yield* streamRes.content;
    }

    return ResultValue(content: func());
  }

  @override
  Result<void> sendItem(T item) {
    if (isInitialized) {
      _channel.sendItem(item).logIfFails(errorName: 'SharedEvent.sendItem -> Failed to send item through the channel');
      return voidResult;
    }

    initialize().onCorrectFuture((_) => sendItem(item)).logIfFails(errorName: 'SharedEvent.sendItem -> Failed to initialize SharedEvent before sending item');
    return voidResult;
  }
}
