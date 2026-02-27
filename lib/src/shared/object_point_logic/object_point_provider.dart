import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/shared/object_point.dart';
import 'package:maxi_thread/src/shared/shared_service.dart';

class RegisterObjectPoint<T extends Object> with FunctionalityMixin<ObjectPoint<T>> {
  final String name;
  final T entity;

  const RegisterObjectPoint({required this.name, required this.entity});

  @override
  Future<Result<ObjectPoint<T>>> runFuncionality() async {
    final connectionResult = await SharedService.connection();
    if (connectionResult.itsFailure) return connectionResult.cast();

    final defResult = ThreadManager.threadZone.defineThreadObject<T>(name: name, object: entity);
    if (defResult.itsFailure) return defResult.cast();

    final service = connectionResult.content;
    final codeResult = await service.executeResult(function: (serv, para) => serv.objectPointManager.defineObjectPoint<T>(name: para.first<String>()));
    if (codeResult.itsFailure) return codeResult.cast();

    final code = codeResult.content;
    final provider = _ObjectPointProvider<T>(name: name, code: code, connection: service, item: entity);

    return provider.asResultValue();
  }
}

//##############################################################################################################

class _ObjectPointProvider<T extends Object> with DisposableMixin, LifecycleHub implements ObjectPoint<T> {
  final String name;
  final int code;
  final EntityThreadConnection<SharedService> connection;
  final T item;

  _ObjectPointProvider({required this.name, required this.code, required this.connection, required this.item}) {
    if (item is Disposable) {
      createDependency(item as Disposable);
    }
  }

  @override
  FutureResult<Channel<S, R>> buildChannel<R, S>({
    InvocationParameters parameters = InvocationParameters.empty,
    required FutureOr<Result<void>> Function(T serv, Channel<R, S> channel, InvocationParameters para) function,
  }) async {
    final channel = joinDisposableObject(MasterChannel<R, S>());

    scheduleMicrotask(() async {
      final result = await function(item, channel, parameters);
      result.logIfFails(errorName: 'ObjectPointProvider -> buildChannel: Failed to execute channel function');
      channel.dispose();
    });

    return channel.buildConnector();
  }

  @override
  Future<Result<R>> execute<R>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<R> Function(T serv, InvocationParameters para) function}) async {
    return (await function(item, parameters)).asFutOptResValue();
  }

  @override
  Future<Result<R>> executeResult<R>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<R>> Function(T serv, InvocationParameters para) function}) async {
    return function(item, parameters);
  }

  @override
  FutureResult<void> releaseProvider() async {
    dispose();
    return voidResult;
  }

  @override
  FutureResult<void> claimProvider({required T item}) {
    // TODO: implement claimProvider
    throw UnimplementedError();
  }

  @override
  void performObjectDiscard() {
    super.performObjectDiscard();

    ThreadManager.threadZone.removeThreadObject<T>(name: name);
    if (item is Disposable) {
      (item as Disposable).dispose();
    }

    connection
        .execute(function: (serv, para) => serv.objectPointManager.declareSupplierClosed(code: para.first<int>()))
        .logIfFails(errorName: 'ObjectPointProvider -> performObjectDiscard: Failed to notify supplier closure');
  }
}
