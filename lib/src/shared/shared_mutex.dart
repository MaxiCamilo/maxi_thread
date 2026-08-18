import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/shared/shared_service.dart';

class SharedMutex {
  final String name;

  const SharedMutex({required this.name});

  FutureResult<T> enqueueFunctionality<T>(Functionality<T> functionality) {
    return SharedService.connection().onCorrectFuture((conn) => conn.executeResult(parameters: InvocationParameters.list([name, functionality]), function: _executeFunctionalityOnSharedService<T>));
  }

  static FutureResult<T> _executeFunctionalityOnSharedService<T>(SharedService serv, InvocationParameters parameters) {
    final name = parameters.first<String>();
    final functionality = parameters.second<Functionality<T>>();
    return serv.executeMutex(name: name, function: () => functionality.executeOnBackground());
  }

  Future<Result<T>> enqueueResult<T>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<T>> Function(InvocationParameters para) function}) {
    return SharedService.connection().onCorrectFuture((conn) => conn.executeResult(parameters: InvocationParameters.list([name, function, parameters]), function: _executeMethodOnSharedService<T>));
  }

  static Future<Result<T>> _executeMethodOnSharedService<T>(SharedService serv, InvocationParameters parameters) {
    final name = parameters.first<String>();
    final function = parameters.second<FutureOr<Result<T>> Function(InvocationParameters)>();
    final para = parameters.third<InvocationParameters>();

    return serv.executeMutex(
      name: name,
      function: () => threadSystem.backgroundService.executeResult(parameters: para, function: function),
    );
  }

  Future<Result<T>> enqueueBackgroundResult<T>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<T>> Function(InvocationParameters para) function}) {
    return enqueueResult<T>(parameters: InvocationParameters.list([parameters, function]), function: _enqueueBackgroundResult<T>);
  }

  static Future<Result<T>> _enqueueBackgroundResult<T>(InvocationParameters parameters) {
    final para = parameters.first<InvocationParameters>();
    final function = parameters.second<FutureOr<Result<T>> Function(InvocationParameters)>();

    return threadSystem.backgroundService.executeResult(parameters: para, function: function);
  }
}
