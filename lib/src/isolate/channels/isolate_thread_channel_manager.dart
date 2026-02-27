import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/isolate/isolated_thread.dart';
import 'package:maxi_thread/src/isolate/channels/isolate_origin_channel.dart';
import 'package:maxi_thread/src/isolate/channels/isolate_reference_channel.dart';
import 'package:maxi_thread/src/thread_connection.dart';
import 'package:maxi_thread/src/thread_singleton.dart';

class IsolateThreadChannelManager with DisposableMixin, LifecycleHub {
  static const String channelParameterName = '%[#MX.ChN]%&¡';

  final _localChannels = <IsolateOriginChannel>[];
  final _referenceChannels = <IsolateReferenceChannel>[];

  int _lastID = 1;

  FutureResult<Channel<S, R>> executeRequest<R, S>({
    required InvocationParameters parameters,
    required FutureOr<Result<void>> Function(Channel<R, S> channel, InvocationParameters para) function,
    required ThreadConnection connection,
  }) async {
    final externalResult = await connection.executeResult(
      parameters: InvocationParameters.addParameters(original: parameters, namedParameters: {channelParameterName: function}),
      function: _createChannel<R, S>,
    );

    if (externalResult.itsFailure) return externalResult.cast();

    final channelId = externalResult.content;
    final newChannel = joinDisposableObject(IsolateReferenceChannel<S, R>(channelId: channelId, origin: connection));
    _referenceChannels.add(newChannel);
    newChannel.onDispose.whenComplete(() => _referenceChannels.remove(newChannel));

    return ResultValue(content: newChannel);
  }

  static FutureResult<int> _createChannel<R, S>(InvocationParameters parameters) async {
    return threadSystem.dynamicCastResult<IsolatedThread>().onCorrectFuture((y) => y.channelManager.buildNewChannel<R, S>(parameters: parameters));
  }

  FutureResult<int> buildNewChannel<R, S>({required InvocationParameters parameters}) async {
    final parameterResult = (parameters.named<Object>(channelParameterName)).dynamicCastResult<FutureOr<Result<void>> Function(Channel<R, S> channel, InvocationParameters parameters)>(
      errorMessage: const FixedOration(message: 'Failed to cast channel builder parameter to expected type Channel Function(InvocationParameters)'),
    );
    if (parameterResult.itsFailure) return parameterResult.cast();

    final connection = ThreadConnection.threadZone;
    final id = _lastID;
    _lastID += 1;
    final channel = joinDisposableObject(IsolateOriginChannel<R, S>(channelId: id, origin: connection, function: parameterResult.content, parameters: parameters));
    _localChannels.add(channel);
    channel.onDispose.whenComplete(() => _localChannels.remove(channel));

    return ResultValue(content: id);
  }

  Result<IsolateReferenceChannel> searchReferenceChannel(int channelId) {
    final localConnection = ThreadConnection.threadZone;
    final itsHasIsolateReferenceChannel = _referenceChannels.any((x) => x.origin.identifier == localConnection.identifier && x.channelId == channelId);
    if (!itsHasIsolateReferenceChannel) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'No reference channels created for thread #%1', textParts: [localConnection.identifier.toString()]),
      );
    }

    final channel = _referenceChannels.selectItem((x) => x.origin.identifier == localConnection.identifier && x.channelId == channelId);
    if (channel == null) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'No reference channel number #%1 found for thread #%2', textParts: [channelId.toString(), localConnection.identifier.toString()]),
      );
    }

    return ResultValue(content: channel);
  }

  Result<IsolateOriginChannel> searchOriginChannel(int channelId) {
    final localConnection = ThreadConnection.threadZone;
    final itsHasIsolateOriginChannel = _localChannels.any((x) => x.channelId == channelId && x.origin.identifier == localConnection.identifier);
    if (!itsHasIsolateOriginChannel) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'No origin channels created for thread #%1', textParts: [localConnection.identifier.toString()]),
      );
    }

    final channel = _localChannels.selectItem((x) => x.channelId == channelId && x.origin.identifier == localConnection.identifier);
    if (channel == null) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'No origin channel number #%1 found for thread #%2', textParts: [channelId.toString(), localConnection.identifier.toString()]),
      );
    }

    return ResultValue(content: channel);
  }
}
