import 'dart:isolate';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/isolate/channels/isolator_channel_end_point.dart';
import 'package:maxi_thread/src/isolate/channels/isolator_channel_initiation_point.dart';
import 'package:maxi_thread/src/isolate/client/isolated_thread_client.dart';
import 'package:maxi_thread/src/isolate/connections/isolate_thread_connection.dart';
import 'package:maxi_thread/src/thread_singleton.dart';

class SpawnIsolate with FunctionalityMixin<IsolateThreadConnection> {
  final int identifier;
  final String name;

  const SpawnIsolate({required this.identifier, required this.name});

  @override
  FutureResult<IsolateThreadConnection> runFuncionality() async {
    final point = IsolatorChannelInitiationPoint();

    final isolate = await Isolate.spawn(_startThread, (identifier, point.output, name), debugName: name);
    final waitConfirmation = await point.waitConfirmation();
    if (!waitConfirmation) {
      isolate.kill(priority: Isolate.immediate);
      return NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: const FixedOration(message: 'Failed to confirm isolate startup'),
      );
    }

    return IsolateThreadConnection(channel: point, identifier: identifier, name: name).asResultValue();
  }

  static void _startThread((int identifier, SendPort sendPort, String name) args) {
    final channel = IsolatorChannelEndPoint(sendPoint: args.$2);
    final isolateManager = IsolatedThreadClient(identifier: args.$1, name: args.$3, channel: channel);

    threadSystem = isolateManager;
  }
}
