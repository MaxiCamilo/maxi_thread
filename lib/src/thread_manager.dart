import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/entity_thread_connection.dart';
import 'package:maxi_thread/src/thread_connection.dart';

/// Signature that defines the operator of a specific thread. Thread operators are unique in the contexts of isolated zones (whether a native thread or a separated part). They are usually found in [threadSystem] in [thread_singleton.dart].
abstract interface class ThreadManager implements Disposable {
  static const kThreadManagerZone = #maxiThreadManager;

  int get identifier;
  String get name;
  ThreadConnection get serverConnection;

  EntityThreadConnection<T> service<T>();

  FutureResult<ThreadConnection> createThread({required String name, List<Functionality> initializers = const []});
  FutureResult<EntityThreadConnection<T>> createEntityThread<T>({required T instance, bool omitIfExists = true});
  FutureResult<ThreadConnection> obtainConnectionFromIdentifier({required int threadIdentifier});

  Result<T> getThreadEntity<T>();

  Result<T> obtainThreadObject<T extends Object>({required String name});
  Result<void> defineThreadObject<T extends Object>({required String name, required T object, bool removePrevious = true});
  Result<bool> hasThreadObject<T extends Object>({required String name});
  Result<void> removeThreadObject<T extends Object>({required String name});

  static ThreadManager get threadZone => Zone.current[kThreadManagerZone]! as ThreadManager;
}
