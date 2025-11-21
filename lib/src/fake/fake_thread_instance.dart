import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/fake/fake_remote_object_manager.dart';
import 'package:maxi_thread/src/fake/fake_thread_services_manager.dart';
import 'package:maxi_thread/src/fake/main_thread_instance.dart';

class FakeThreadInstance implements ThreadInstance {
  @override
  int get identifier => 0;

  @override
  ThreadInvocator get background => const MainThreadInstance();

  @override
  Future<Result<ThreadInvocator>> createThread({required String name}) async {
    return const ResultValue(content: MainThreadInstance());
  }

  @override
  ThreadInvocator get server => const MainThreadInstance();

  @override
  final ThreadServiceManager services = FakeThreadServicesManager();

  @override
  final ThreadRemoteObjectManager remoteObjects = FakeRemoteObjectManager();
}
