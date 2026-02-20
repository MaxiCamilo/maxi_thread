import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/isolate/isolated_thread.dart';
import 'package:maxi_thread/src/isolate/operators/isolate_origin_channel.dart';
import 'package:maxi_thread/src/isolate/operators/isolate_reference_channel.dart';
import 'package:maxi_thread/src/thread_connection.dart';
import 'package:maxi_thread/src/thread_singleton.dart';

class IsolateThreadChannelManager with DisposableMixin, LifecycleHub {
  static const String channelParameterName = '%[#MX.ChN]%&¡';

  final _localChannels = <IsolateOriginChannel>[];
  final _referenceChannels = <IsolateReferenceChannel>[];

  int _lastID = 1;

  FutureResult<Channel<S, R>> executeRequest<R, S>({
    required InvocationParameters parameters,
    required FutureOr<Result<Channel<R, S>>> Function(InvocationParameters para) function,
    required ThreadConnection connection,
  }) async {
    final externalResult = await connection.executeResult(
      parameters: InvocationParameters.addParameters(original: parameters, namedParameters: {channelParameterName: function}),
      function: _createChannel<R, S>,
    );

    if (externalResult.itsFailure) externalResult.cast();

    final channelId = externalResult.content;
    final newChannel = joinDisposableObject(IsolateReferenceChannel<R, S>(connection: connection, channelID: channelId));
    _referenceChannels.add(newChannel);

    newChannel.onDispose.whenComplete(() {
      _referenceChannels.remove(newChannel);
      connection
          .executeResult(function: _requestEndLocalChannel, parameters: InvocationParameters.only(channelId))
          .logIfFails(errorName: 'IsolateThreadChannelManager -> executeRequest: Failed to notify origin about channel discard');
    });

    return newChannel.channel.buildConnector();
  }

  static FutureResult<int> _createChannel<R, S>(InvocationParameters parameters) async {
    return threadSystem.dynamicCastResult<IsolatedThread>().onCorrectFuture((y) => y.channelManager.buildNewChannel<R, S>(parameters: parameters));
  }

  static Result<void> _requestEndLocalChannel(InvocationParameters parameters) {
    final channelId = parameters.first<int>();
    final channelManagerResult = threadSystem.dynamicCastResult<IsolatedThread>(errorMessage: const FixedOration(message: 'Failed to cast thread system to IsolatedThread')).select((x) => x.channelManager);

    if (channelManagerResult.itsFailure) return channelManagerResult.cast();
    final channelManager = channelManagerResult.content;

    final channel = channelManager._localChannels.selectItem((x) => x.channelId == channelId && x.origin.identifier == ThreadConnection.threadZone.identifier);
    if (channel != null) {
      channelManager._localChannels.remove(channel);
      channel.dispose();
    }

    return voidResult;
  }

  FutureResult<int> buildNewChannel<R, S>({required InvocationParameters parameters}) async {
    final parameterResult = (parameters.named<Object>(channelParameterName)).dynamicCastResult<FutureOr<Result<Channel<R, S>>> Function(InvocationParameters)>(
      errorMessage: const FixedOration(message: 'Failed to cast channel builder parameter to expected type Channel Function(InvocationParameters)'),
    );
    if (parameterResult.itsFailure) return parameterResult.cast();

    final connection = ThreadConnection.threadZone;

    final channelResult = await parameterResult.content(parameters);
    if (channelResult.itsFailure) return channelResult.cast();

    final id = _lastID;
    _lastID += 1;

    final referenceChannel = joinDisposableObject(IsolateOriginChannel(channelId: id, channel: channelResult.content, origin: connection));

    _localChannels.add(referenceChannel);
    referenceChannel.onDispose.whenComplete(() => _localChannels.remove(referenceChannel));

    return ResultValue(content: id);
  }

  void notifyExternalChannelDiscard({required int channelId}) {
    final localConnection = ThreadConnection.threadZone;
    final channel = _referenceChannels.selectItem((x) => x.connection.identifier == localConnection.identifier && x.channelID == channelId);
    if (channel != null) {
      channel.dispose();
      _referenceChannels.remove(channel);
    }
  }

  Result<IsolateReferenceChannel> _searchReferenceChannel(int channelId) {
    final localConnection = ThreadConnection.threadZone;
    final itsHasIsolateReferenceChannel = _referenceChannels.any((x) => x.connection.identifier == localConnection.identifier && x.channelID == channelId);
    if (!itsHasIsolateReferenceChannel) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'No channels created for thread #%1', textParts: [localConnection.identifier.toString()]),
      );
    }

    final channel = _referenceChannels.selectItem((x) => x.connection.identifier == localConnection.identifier && x.channelID == channelId);
    if (channel == null) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'No channel number #%1 found for thread #%2', textParts: [channelId.toString(), localConnection.identifier.toString()]),
      );
    }

    return ResultValue(content: channel);
  }

  Result<void> notifyItem({required int channelId, required dynamic item}) {
    final channelResult = _searchReferenceChannel(channelId);
    if (channelResult.itsFailure) return channelResult.cast();

    channelResult.content.channel.sendItem(item).logIfFails(errorName: 'IsolateThreadChannelManager -> notifyItem: Failed to send item to reference channel');
    return voidResult;
  }

  Result<void> notifyError({required int channelId, required Object error, required StackTrace stackTrace}) {
    return notifyItem(
      channelId: channelId,
      item: ExceptionResult(
        exception: error,
        stackTrace: stackTrace,
        message: const FixedOration(message: 'Stream error'),
      ),
    );
  }
}
