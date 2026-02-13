import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/entity_thread_connection.dart';
import 'package:maxi_thread/src/thread_connection.dart';

abstract interface class ThreadManager implements Disposable {
  static const kThreadManagerZone = #maxiThreadManager;

  int get identifier;
  String get name;
  ThreadConnection get serverConnection;

  EntityThreadConnection<T> service<T>();

  FutureResult<ThreadConnection> createThread({required String name, List<Functionality> initializers = const []});
  FutureResult<EntityThreadConnection<T>> createEntityThread<T>({required T instance, bool omitIfExists = true});
  FutureResult<ThreadConnection> obtainConnectionFromIdentifier({required int threadIdentifier});

  static ThreadManager get threadZone => Zone.current[kThreadManagerZone]! as ThreadManager;
}
