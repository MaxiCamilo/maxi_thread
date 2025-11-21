import 'dart:isolate';

import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/isolated/clients/isolated_services_client_connection.dart';
import 'package:maxi_thread/src/isolated/clients/isolated_thread_client.dart';
import 'package:maxi_thread/src/isolated/server/isolated_service_server_instance.dart';

class IsolatedServicesClientManager implements ThreadServiceManager {
  final IsolatedThreadClient invocator;
  final ThreadInvocator serverConnection;

  final List<ThreadServiceInvocator> _services = [];

  IsolatedServicesClientManager({required this.invocator, required this.serverConnection});

  @override
  Future<Result<bool>> hasService(Type type) async {
    if (_services.any((element) => element.isCompatible(type))) {
      return ResultValue(content: true);
    }

    return serverConnection.executeResult(parameters: InvocationParameters.only(type), function: (para) => ThreadInstance.getIsolatedInstance().onCorrectFuture((x) => x.services.hasService(para.firts<Type>())));
  }

  @override
  Future<Result<ThreadServiceInvocator<T>>> createServiceThread<T extends Object>({required T item, bool skipIfAlreadyMounted = true, String? name}) async {
    final wasMounted = await hasService(T);
    if (wasMounted.itsFailure) return wasMounted.cast();

    if (wasMounted.content) {
      if (skipIfAlreadyMounted) {
        final existingService = _services.selectType<ThreadServiceInvocator<T>>();
        if (existingService != null) {
          return ResultValue(content: existingService);
        }
      } else {
        return NegativeResult.controller(
          code: ErrorCode.implementationFailure,
          message: FlexibleOration(message: 'Service %1 has already been mounted', textParts: [T]),
        );
      }
    }

    final sendPortResult = await serverConnection.executeResult(parameters: InvocationParameters.list([item, skipIfAlreadyMounted, name]), function: (para) => _createEntityInServer<T>(para));
    if (sendPortResult.itsFailure) return sendPortResult.cast();

    final newInstance = IsolatedServicesClientConnection<T>(connector: sendPortResult.content, invocator: invocator, serverConnection: serverConnection);

    final newInstanceInitialization = await newInstance.initialize();
    if (newInstanceInitialization.itsFailure) return newInstanceInitialization.cast();

    _services.add(newInstance);

    newInstance.onDispose.whenComplete(() => _services.remove(newInstance));
    return newInstance.asResultValue();
  }

  static Future<Result<SendPort>> _createEntityInServer<T extends Object>(InvocationParameters para) async {
    final item = para.firts<T>();
    final skipIfAlreadyMounted = para.second<bool>();
    final name = para.third<String?>();

    final threadInstance = ThreadInstance.getIsolatedInstance();
    final serviceManager = threadInstance.content;

    final serviceResult = await serviceManager.services.createServiceThread<T>(item: item, skipIfAlreadyMounted: skipIfAlreadyMounted, name: name);
    if (serviceResult.itsFailure) return serviceResult.cast();

    final connector = await (serviceResult.content as IsolatedServiceServerInstance).getSendPort();
    return connector;
  }

  @override
  Result<ThreadServiceInvocator<T>> getServiceInvocator<T extends Object>() {
    final founded = _services.selectItem((x) => x.isCompatible(T));
    if (founded != null) {
      return founded.asResultValue().cast<ThreadServiceInvocator<T>>();
    }

    final newInstance = IsolatedServicesClientConnection<T>(connector: null, invocator: invocator, serverConnection: serverConnection);
    _services.add(newInstance);
    return newInstance.asResultValue();
  }
}
