import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/entity_thread_connection.dart';
import 'package:maxi_thread/src/thread_connection.dart';
import 'package:maxi_thread/src/thread_manager.dart';

ThreadManager threadSystem = const ThreadManagerInitializer();

class ThreadManagerInitializer implements ThreadManager {
  const ThreadManagerInitializer();

  @override
  FutureResult<EntityThreadConnection<T>> createEntityThread<T>({required T instance, bool omitIfExists = true}) {
    // TODO: implement createEntityThread
    throw UnimplementedError();
  }

  @override
  // TODO: implement identifier
  int get identifier => throw UnimplementedError();

  @override
  // TODO: implement serverConnection
  ThreadConnection get serverConnection => throw UnimplementedError();

  @override
  EntityThreadConnection<T> service<T>() {
    // TODO: implement service
    throw UnimplementedError();
  }

  @override
  FutureResult<ThreadConnection> createThread({List<Functionality> initializers = const []}) {
    // TODO: implement createThread
    throw UnimplementedError();
  }

  @override
  void dispose() {
    // TODO: implement dispose
  }

  @override
  // TODO: implement itWasDiscarded
  bool get itWasDiscarded => throw UnimplementedError();

  @override
  // TODO: implement name
  String get name => throw UnimplementedError();

  @override
  FutureResult<ThreadConnection> obtainConnectionFromIdentifier({required int threadIdentifier}) {
    // TODO: implement obtainConnectionFromIdentifier
    throw UnimplementedError();
  }

  @override
  // TODO: implement onDispose
  Future<dynamic> get onDispose => throw UnimplementedError();
}
