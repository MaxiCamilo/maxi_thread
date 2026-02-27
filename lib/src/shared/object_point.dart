import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/shared/object_point_logic/object_point_provider.dart';
import 'package:maxi_thread/src/shared/object_point_logic/object_point_reference.dart';
import 'package:maxi_thread/src/shared/shared_service.dart';

abstract interface class ObjectPoint<T extends Object> implements Disposable {
  FutureResult<void> claimProvider({required T item});
  FutureResult<void> releaseProvider();

  Future<Result<R>> execute<R>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<R> Function(T serv, InvocationParameters para) function});
  Future<Result<R>> executeResult<R>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<R>> Function(T serv, InvocationParameters para) function});
  FutureResult<Channel<S, R>> buildChannel<R, S>({
    InvocationParameters parameters = InvocationParameters.empty,
    required FutureOr<Result<void>> Function(T serv, Channel<R, S> channel, InvocationParameters para) function,
  });

  factory ObjectPoint({required String name}) {
    return _ObjectPointMask<T>(name: 'Mx.Sp.$name', isProviderClaimed: false);
  }

  static FutureResult<bool> hasProviderNamed<T>({required String name}) => SharedService.connection().onCorrectFuture(
    (x) => x.executeResult(
      parameters: InvocationParameters.only('Mx.Sp.$name'),
      function: (serv, para) => serv.objectPointManager.hasProvider<T>(name: para.first<String>()),
    ),
  );
}

//##############################################################################################################

class _ObjectPointMask<T extends Object> with AsynchronouslyInitializedMixin implements ObjectPoint<T> {
  final String name;
  bool isProviderClaimed;

  late ObjectPoint<T> _mask;
  late T _item;

  _ObjectPointMask({required this.name, required this.isProviderClaimed});

  @override
  Future<Result<void>> performInitialize() async {
    late final Result<ObjectPoint<T>> maskResult;

    if (isProviderClaimed) {
      maskResult = await RegisterObjectPoint<T>(name: name, entity: _item).execute();
    } else {
      maskResult = await FindObjectPoint<T>(name: name).execute();
    }

    if (maskResult.itsFailure) return maskResult.cast();

    _mask = maskResult.content;
    _mask.onDispose.whenComplete(dispose);

    return voidResult;
  }

  @override
  void performObjectDiscard(bool itsWasInitialized) {
    super.performObjectDiscard(itsWasInitialized);

    if (itsWasInitialized) {
      _mask.releaseProvider();
      _mask.dispose();
    }
  }

  @override
  FutureResult<Channel<S, R>> buildChannel<R, S>({
    InvocationParameters parameters = InvocationParameters.empty,
    required FutureOr<Result<dynamic>> Function(T serv, Channel<R, S> channel, InvocationParameters para) function,
  }) async {
    await initialize();
    return await _mask.buildChannel<R, S>(parameters: parameters, function: function);
  }

  @override
  Future<Result<R>> execute<R>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<R> Function(T serv, InvocationParameters para) function}) async {
    await initialize();
    return await _mask.execute<R>(parameters: parameters, function: function);
  }

  @override
  Future<Result<R>> executeResult<R>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<R>> Function(T serv, InvocationParameters para) function}) async {
    await initialize();
    return await _mask.executeResult<R>(parameters: parameters, function: function);
  }

  @override
  FutureResult<void> claimProvider({required T item}) async {
    if (isInitialized) {
      if (isProviderClaimed && (item == _item)) return voidResult;
      isProviderClaimed = false;
      dispose();
      await Future.delayed(Duration.zero);
    }

    _item = item;
    isProviderClaimed = true;
    return await initialize();
  }

  @override
  FutureResult<void> releaseProvider() async {
    if (isInitialized && isProviderClaimed) {
      _mask.releaseProvider();
      _mask.dispose();
    }

    isProviderClaimed = false;
    return voidResult;
  }
}
