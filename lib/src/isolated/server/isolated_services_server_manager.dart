import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/isolated/logic/prepare_service.dart';
import 'package:maxi_thread/src/isolated/server/isolated_service_server_instance.dart';
import 'package:maxi_thread/src/isolated/server/isolated_thread_server.dart';

class IsolatedServicesServerManager implements ThreadServiceManager {
  final _services = <ThreadServiceInvocator>[];

  final IsolatedThreadServer invocator;

  IsolatedServicesServerManager({required this.invocator});

  @override
  Future<Result<bool>> hasService(Type type) async => _services.any((element) => element.isCompatible(type)).asResultValue();

  @override
  Result<ThreadServiceInvocator<T>> getServiceInvocator<T extends Object>() {
    final service = _services.selectItem((x) => x.isCompatible(T));
    if (service == null) {
      return NegativeResult.controller(
        code: ErrorCode.nonExistent,
        message: FlexibleOration(message: 'A service of type %1 has not been mounted', textParts: [T]),
      );
    } else {
      return service.asResultValue();
    }
  }

  @override
  Future<Result<ThreadServiceInvocator<T>>> createServiceThread<T extends Object>({required T item, bool skipIfAlreadyMounted = true, String? name}) async {
    final actualInstance = _services.selectType<ThreadServiceInvocator<T>>();
    if (actualInstance != null) {
      if (skipIfAlreadyMounted) {
        return ResultValue(content: actualInstance);
      } else {
        return NegativeResult.controller(
          code: ErrorCode.implementationFailure,
          message: FlexibleOration(message: 'Service %1 has already been mounted', textParts: [T]),
        );
      }
    }

    if (name == null && item is ThreadService) {
      name = item.serviceName;
    } else {
      name ??= T.toString();
    }
    final threadResult = await invocator.createThread(name: name);
    if (threadResult.itsFailure) return threadResult.cast();

    final initResult = await PrepareService<T>(service: item).inThread(threadResult.content);
    if (initResult.itsCorrect) {
      final newService = IsolatedServiceServerInstance<T>(invocator: threadResult.content);
      _services.add(newService);
      threadResult.content.onDispose.whenComplete(() => _services.remove(newService));
      return newService.asResultValue();
    } else {
      threadResult.content.closeThread();
      return initResult.cast();
    }
  }
}
