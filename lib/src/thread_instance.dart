import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';

abstract interface class ThreadInstance {
  ThreadInvocator get server;
  ThreadInvocator get background;

  ThreadInvocator service<T extends Object>();

  T? getEntityThread<T>();
  Future<Result<ThreadInvocator>> createThread({required String name});

  //Future<Result<ThreadInvocator>> createThread({required String name});
  Future<Result<ThreadInvocator>> createServiceThread<T extends Object>({required T item, bool skipIfAlreadyMounted = true, String? name});
}
