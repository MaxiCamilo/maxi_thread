import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/fake/fake_thread_service_instance.dart';

class FakeThreadServicesManager implements ThreadServiceManager {
  final _instances = <FakeThreadServiceInstance>[];

  @override
  Future<Result<bool>> hasService(Type type) async => _instances.any((element) => element.isCompatible(type)).asResultValue();

  @override
  Result<ThreadServiceInvocator<T>> getServiceInvocator<T extends Object>() {
    final intanceResult = _instances
        .selectItem((x) => x.isCompatible(T))
        .asResErrorIfItsNull(
          message: FlexibleOration(message: 'The service %1 has not been mounted previously', textParts: [T]),
        );

    if (intanceResult.itsFailure) return intanceResult.cast();

    return intanceResult.cast<ThreadServiceInvocator<T>>();
  }

  @override
  Future<Result<ThreadServiceInvocator<T>>> createServiceThread<T extends Object>({required T item, bool skipIfAlreadyMounted = true, String? name}) async {
    final exists = _instances.selectItem((x) => x.isCompatible(T));
    if (exists != null) {
      if (skipIfAlreadyMounted) {
        return exists.asResultValue().cast<ThreadServiceInvocator<T>>();
      } else {
        return NegativeResult.controller(
          code: ErrorCode.unacceptedState,
          message: FlexibleOration(message: 'The service %1 has already been mounted', textParts: [T]),
        );
      }
    }

    final instanceResult = await FakeThreadServiceInstance.instanced<T>(item: item);
    if (instanceResult.itsFailure) return instanceResult.cast();

    _instances.add(instanceResult.content);

    return instanceResult;
  }
}
