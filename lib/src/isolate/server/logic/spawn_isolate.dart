import 'dart:isolate';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/isolate/communication/isolator_channel_end_point.dart';
import 'package:maxi_thread/src/isolate/communication/isolator_channel_initiation_point.dart';
import 'package:maxi_thread/src/isolate/client/isolated_thread_client.dart';
import 'package:maxi_thread/src/isolate/connections/isolate_thread_connection.dart';
import 'package:maxi_thread/src/thread_singleton.dart';

/// The `SpawnIsolate` class is responsible for spawning a new isolate thread and establishing a connection to it. It takes an identifier and a name as parameters, which are used to identify the isolate thread. The `runFuncionality` method creates an initiation point for the isolator channel, spawns the isolate thread, and waits for confirmation of its startup. If the startup is successful, it returns an `IsolateThreadConnection` that can be used to communicate with the newly spawned isolate thread. If there is an error during the startup process, it handles the error appropriately and ensures that resources are cleaned up if necessary. The static method `_startThread` is executed within the context of the newly spawned isolate thread and is responsible for setting up the thread manager and establishing communication with the main thread through the isolator channel. This class serves as a crucial component in managing the lifecycle of isolate threads and facilitating communication between the main thread and the isolate threads in a multi-threaded application. 
class SpawnIsolate with FunctionalityMixin<IsolateThreadConnection> {
  final int identifier;
  final String name;

  const SpawnIsolate({required this.identifier, required this.name});

  @override
  /// Executes the functionality of spawning a new isolate thread and establishing a connection to it. This method creates an initiation point for the isolator channel, spawns the isolate thread, and waits for confirmation of its startup. If the startup is successful, it returns an `IsolateThreadConnection` that can be used to communicate with the newly spawned isolate thread. If there is an error during the startup process, it handles the error appropriately and ensures that resources are cleaned up if necessary. This method allows for effective management of isolate threads and facilitates communication between the main thread and the isolate threads in a multi-threaded application.
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

  /// A static function that is executed within the context of the newly spawned isolate thread. This function is responsible for setting up the thread manager and establishing communication with the main thread through the isolator channel. It creates an `IsolatorChannelEndPoint` using the provided send port, initializes an `IsolatedThreadClient` with the identifier, name, and channel, and assigns it to the thread system. This function ensures that the isolate thread is properly set up to communicate with the main thread and manage its lifecycle effectively.
  static void _startThread((int identifier, SendPort sendPort, String name) args) {
    final channel = IsolatorChannelEndPoint(sendPoint: args.$2);
    final isolateManager = IsolatedThreadClient(identifier: args.$1, name: args.$3, channel: channel);

    threadSystem = isolateManager;
  }
}
