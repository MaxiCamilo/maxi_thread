import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/entity_thread_connection.dart';
import 'package:maxi_thread/src/thread_connection.dart';
import 'package:maxi_thread/src/thread_manager.dart';

import 'factories/native_thread_factory.dart' if (dart.library.html) 'factories/fake_thread_factory.dart';

ThreadManager _kThreadSystem = const ThreadManagerInitializer();

ThreadManager get threadSystem => _kThreadSystem;
set threadSystem(ThreadManager newSystem) {
  if (!_kThreadSystem.itWasDiscarded) {
    log('[ThreadSingleton -> threadSystem] Warning: Reassigning threadSystem while the previous one was not discarded. This may lead to unexpected behavior.', name: 'ThreadSingleton');
  }
  _kThreadSystem = newSystem;
}

class ThreadManagerInitializer implements ThreadManager {
  const ThreadManagerInitializer();

  ThreadManager _defineThreadSystem() {
    final newThread = buildThreadManager();
    threadSystem = newThread;
    return newThread;
  }

  @override
  FutureResult<EntityThreadConnection<T>> createEntityThread<T>({required T instance, bool omitIfExists = true}) {
    return _defineThreadSystem().createEntityThread<T>(instance: instance, omitIfExists: omitIfExists);
  }

  @override
  int get identifier => _defineThreadSystem().identifier;

  @override
  ThreadConnection get serverConnection => _defineThreadSystem().serverConnection;

  @override
  EntityThreadConnection<T> service<T>() {
    return _defineThreadSystem().service<T>();
  }

  @override
  void dispose() {}

  @override
  bool get itWasDiscarded => true;

  @override
  String get name => _defineThreadSystem().name;

  @override
  FutureResult<ThreadConnection> obtainConnectionFromIdentifier({required int threadIdentifier}) {
    return _defineThreadSystem().obtainConnectionFromIdentifier(threadIdentifier: threadIdentifier);
  }

  @override
  Future<dynamic> get onDispose => _defineThreadSystem().onDispose;

  @override
  FutureResult<ThreadConnection> createThread({required String name, List<Functionality<dynamic>> initializers = const []}) {
    return _defineThreadSystem().createThread(name: name, initializers: initializers);
  }

  @override
  Result<T> getThreadEntity<T>() {
    return _defineThreadSystem().getThreadEntity<T>();
  }
}
