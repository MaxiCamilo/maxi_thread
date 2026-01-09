import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

class RemoteObjectFactory<T> with AsynchronouslyInitializedMixin implements RemoteObject<T> {
  final FutureOr<RemoteObject<T>> Function() _getter;

  late RemoteObject<T> _pointer;

  RemoteObjectFactory._({required FutureOr<RemoteObject<T>> Function() getter}) : _getter = getter;

  

  @override
  Future<Result<void>> performInitialize() {
    return _getter()
        .asResultValue()
        .whenItsCorrectVoid((x) {
          _pointer = x;
          if (x is Disposable) {
            snagOnAnotherObject(patern: x);
            x.onDispose.whenComplete(dispose);
          }
        })
        .logIfFails(errorName: 'Initialize Remote Object');
  }

  @override
  Future<Result<R>> execute<R>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<R> Function(T item, InvocationParameters para) function}) {
    return initialize().onCorrectFuture((_) => _pointer.execute<R>(parameters: parameters, function: function));
  }

  @override
  Future<Result<R>> executeResult<R>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Result<R>> Function(T item, InvocationParameters para) function}) {
    return initialize().onCorrectFuture((_) => _pointer.executeResult<R>(parameters: parameters, function: function));
  }

  @override
  Future<Result<T>> getItem() {
    return initialize().onCorrectFuture((_) => _pointer.getItem());
  }

  @override
  Stream<T> get notifyChange async* {
    final init = await initialize();
    if (init.itsFailure) throw init;

    yield* _pointer.notifyChange;
  }
}
