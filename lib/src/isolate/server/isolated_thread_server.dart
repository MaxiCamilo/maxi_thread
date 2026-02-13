import 'dart:isolate';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/entity_thread_connection.dart';
import 'package:maxi_thread/src/isolate/isolated_thread.dart';
import 'package:maxi_thread/src/isolate/server/logic/initialize_isolate_thread.dart';
import 'package:maxi_thread/src/isolate/server/logic/spawn_isolate.dart';
import 'package:maxi_thread/src/thread_connection.dart';

class IsolatedThreadServer extends IsolatedThread {
  @override
  int get identifier => 0;

  @override
  String get name => 'Isolated Thread Server';

  final _spawnMutex = Mutex();

  int _lastIdentifier = 1;

  @override
  FutureResult<ThreadConnection> createThread({required String name, List<Functionality> initializers = const []}) async {
    final spawnResult = await _spawnMutex.execute(() {
      final init = SpawnIsolate(identifier: _lastIdentifier, name: name);
      _lastIdentifier += 1;
      return init.execute();
    });

    if (spawnResult.itsFailure) {
      return spawnResult.cast();
    }

    final initializationResult = await spawnResult.content.executeResult(parameters: InvocationParameters.only(initializers), function: InitializeIsolateThread.runInThread);
  }

  @override
  FutureResult<EntityThreadConnection<T>> createEntityThread<T>({required T instance, bool omitIfExists = true}) {
    // TODO: implement createEntityThread
    throw UnimplementedError();
  }

  @override
  // TODO: implement serverConnection
  ThreadConnection get serverConnection => throw UnimplementedError();

  @override
  EntityThreadConnection<T> service<T>() {
    // TODO: implement service
    throw UnimplementedError();
  }

  @override
  FutureResult<ThreadConnection> obtainConnectionFromIdentifier({required int threadIdentifier}) async {
    for (final item in externalConnections) {
      if (item.identifier == threadIdentifier) {
        return item.asResultValue();
      }
    }

    return NegativeResult.controller(
      code: ErrorCode.nonExistent,
      message: FlexibleOration(message: 'Thread #%1 does not exist', textParts: [threadIdentifier.toString()]),
    );
  }
}
