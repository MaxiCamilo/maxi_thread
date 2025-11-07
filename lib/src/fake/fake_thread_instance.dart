import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/fake/main_thread_instance.dart';

class FakeThreadInstance implements ThreadInstance {
  final List _entities = [];

  @override
  ThreadInvocator get background => const MainThreadInstance();

  @override
  Future<Result<ThreadInvocator>> createThread({required String name}) async {
    return const ResultValue(content: MainThreadInstance());
  }

  @override
  ThreadInvocator get server => const MainThreadInstance();

  @override
  Result<ThreadInvocator> getService<T extends Object>() {
    return ResultValue(content: const MainThreadInstance());
  }

  @override
  T? getEntityThread<T>() {
    return _entities.selectItem((x) => x.runtimeType == T && x is T);
  }

  @override
  Future<Result<ThreadInvocator>> createServiceThread<T extends Object>({required T item, bool skipIfAlreadyMounted = true, String? name}) async {
    final exists = getEntityThread<T>();
    if (exists != null) {
      if (skipIfAlreadyMounted) {
        return const ResultValue(content: MainThreadInstance());
      } else {
        return NegativeResult.controller(
          code: ErrorCode.implementationFailure,
          message: FlexibleOration(message: 'The service %1 was previously mounted', textParts: [T]),
        );
      }
    }

    _entities.add(item);
    return const ResultValue(content: MainThreadInstance());
  }
}
