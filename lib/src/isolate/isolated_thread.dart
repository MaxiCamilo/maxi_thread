import 'dart:isolate';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/isolate/channels/isolator_channel_initiation_point.dart';
import 'package:maxi_thread/src/isolate/connections/isolate_thread_connection.dart';
import 'package:maxi_thread/src/thread_connection.dart';
import 'package:maxi_thread/src/thread_manager.dart';
import 'package:meta/meta.dart';

abstract class IsolatedThread with DisposableMixin, LifecycleHub implements ThreadManager {
  final externalConnections = <IsolateThreadConnection>{};
  final pendingConnections = <IsolatorChannelInitiationPoint>{};

  @protected
  Result<SendPort> obtainSendPort({required ThreadConnection connection}) {
    final pending = joinDisposableObject(IsolatorChannelInitiationPoint());

    pendingConnections.add(pending);
    pending.waitConfirmation().then((itsInitialize) {
      pendingConnections.remove(pending);
      if (itsInitialize) {
        _createChannelFromPending(pending).logIfFails(errorName: 'IsolatedThread -> ObtainSendPort: Initilization failed');
      }
    });

    return pending.output.asResultValue<SendPort>();
  }

  FutureResult<void> _createChannelFromPending(IsolatorChannelInitiationPoint pending) async {
    final newConnection = joinDisposableObject(IsolateThreadConnection(channel: pending));
    final dataResult = await newConnection.obtaintThreadData();
    if (dataResult.itsFailure) {
      newConnection.dispose();
      return dataResult;
    }

    externalConnections.add(newConnection);
    return voidResult;
  }
}
