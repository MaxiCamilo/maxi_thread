import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/fake/fake_thread_connection.dart';

class FakeEntityConnection<T> with DisposableMixin, AsynchronouslyInitializedMixin implements EntityThreadConnection<T> {
  final FakeThreadConnection connection;
  final T instance;

  FakeEntityConnection({required this.connection, required this.instance});

  @override
  Future<Result<void>> performInitialize() async {
    if (T is Disposable) {
      (instance as Disposable).onDispose.whenComplete(dispose);
      onDispose.whenComplete((instance as Disposable).dispose);
    }

    if (T is Initializable) {
      final initResult = (instance as Initializable).initialize();
      if (initResult.itsFailure) {
        return initResult.cast();
      }
    }

    if (T is AsynchronouslyInitialized) {
      final asyncInitResult = await (instance as AsynchronouslyInitialized).initialize();
      if (asyncInitResult.itsFailure) {
        return asyncInitResult.cast();
      }
    }

    return voidResult;
  }

  @override
  FutureResult<Channel<S, R>> buildChannel<R, S>({
    InvocationParameters parameters = InvocationParameters.empty,
    required FutureOr<Result<dynamic>> Function(T serv, Channel<R, S> channel, InvocationParameters para) function,
  }) {
    return connection.buildChannel<R, S>(parameters: parameters, function: (channel, para) => function(instance, channel, para));
  }

  @override
  Future<Result<R>> execute<R>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<R> Function(T serv, InvocationParameters para) function}) {
    return connection.execute<R>(parameters: parameters, function: (para) => function(instance, para));
  }

  @override
  Future<Result<R>> executeResult<R>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<R>> Function(T serv, InvocationParameters para) function}) {
    return connection.executeResult<R>(parameters: parameters, function: (para) => function(instance, para));
  }
}
