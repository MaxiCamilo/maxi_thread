import 'dart:async';
import 'dart:io';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/isolate/server/isolated_thread_server.dart';

class BackgroundIsolateServer implements BackgroundThreadService {
  final IsolatedThreadServer server;

  final _mutex = Mutex();
  late final int _maximumThreads;
  final _inactiveThreads = <ThreadConnection>[];
  Completer<ThreadConnection>? _threadWaiter;

  BackgroundIsolateServer({required this.server}) {
    _maximumThreads = Platform.numberOfProcessors * 2;
  }

  FutureResult<ThreadConnection> _createBackgroundThread() {
    return _mutex.execute(() async {
      if (_inactiveThreads.isNotEmpty) {
        return _inactiveThreads.removeLast().asResultValue();
      }

      if (server.externalConnections.length >= _maximumThreads) {
        _threadWaiter ??= Completer<ThreadConnection>();
        final waitResult = await LifeCoordinator.zoneHeart.lifecycleScope.waitCompleter(_threadWaiter!);
        _threadWaiter = null;
        return waitResult.asResultValue();
      }

      final newConnectionResult = await server.createThread(name: 'BackgroundThread-${server.externalConnections.length + 1}');
      return newConnectionResult;
    });
  }

  @override
  Future<Result<T>> execute<T>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<T> Function(InvocationParameters para) function}) {
    return _createBackgroundThread().onCorrectFuture((thread) => thread.execute<T>(parameters: parameters, function: function).breakIfCanceled().whenComplete(() => _onDone(thread)));
  }

  void _onDone(ThreadConnection thread) {
    if (_threadWaiter == null || _threadWaiter!.isCompleted) {
      _inactiveThreads.add(thread);
    } else {
      _threadWaiter!.complete(thread);
      _threadWaiter = null;
    }
  }

  @override
  Future<Result<T>> executeResult<T>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<T>> Function(InvocationParameters para) function}) {
    return _createBackgroundThread().onCorrectFuture((thread) => thread.executeResult<T>(parameters: parameters, function: function).breakIfCanceled().whenComplete(() => _onDone(thread)));
  }
}
