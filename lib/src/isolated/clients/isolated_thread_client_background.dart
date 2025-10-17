import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/isolated/connections/isolated_thread_connection.dart';

class IsolatedThreadClientBackground implements ThreadInvocator {
  final IsolatedThreadConnection server;

  const IsolatedThreadClientBackground({required this.server});

  @override
  Future<Result<T>> execute<T>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<T> Function(InvocationParameters para) function}) {
    return server.execute<T>(function: _execute<T>, parameters: InvocationParameters.clone(parameters, avoidConstants: true)..namedParameters['&%=*'] = function);
  }

  static Future<T> _execute<T>(InvocationParameters parameters) async {
    final function = parameters.named<FutureOr<T> Function(InvocationParameters)>('&%=*');
    return (await ThreadSingleton.background.execute(function: function, parameters: parameters)).content;
  }

  @override
  Future<Result<T>> executeResult<T>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Result<T>> Function(InvocationParameters para) function}) {
    return server.executeResult<T>(function: _executeResult<T>, parameters: InvocationParameters.clone(parameters, avoidConstants: true)..namedParameters['&%=*'] = function);
  }

  static Future<Result<T>> _executeResult<T>(InvocationParameters parameters) {
    final function = parameters.named<FutureOr<Result<T>> Function(InvocationParameters)>('&%=*');
    return ThreadSingleton.background.executeResult(function: function, parameters: parameters);
  }

  @override
  Future<Result<T>> executeInteractively<I, T>({InvocationParameters parameters = InvocationParameters.emptry, required void Function(I item) onItem, required FutureOr<T> Function(InvocationParameters para) function}) {
    return server.executeInteractively<I, T>(function: _executeInteractively<I, T>, parameters: InvocationParameters.clone(parameters, avoidConstants: true)..namedParameters['&%=*'] = function, onItem: onItem);
  }

  static Future<T> _executeInteractively<I, T>(InvocationParameters parameters) async {
    final function = parameters.named<FutureOr<T> Function(InvocationParameters)>('&%=*');
    return (await ThreadSingleton.background.executeInteractively<I, T>(function: function, parameters: parameters, onItem: InteractiveSystem.sendItem)).content;
  }

  @override
  Future<Result<T>> executeInteractivelyResult<I, T>({
    InvocationParameters parameters = InvocationParameters.emptry,
    required void Function(I item) onItem,
    required FutureOr<Result<T>> Function(InvocationParameters para) function,
  }) {
    return server.executeInteractivelyResult<I, T>(
      function: _executeInteractivelyResult<I, T>,
      parameters: InvocationParameters.clone(parameters, avoidConstants: true)..namedParameters['&%=*'] = function,
      onItem: onItem,
    );
  }

  static Future<Result<T>> _executeInteractivelyResult<I, T>(InvocationParameters parameters) {
    final function = parameters.named<FutureOr<Result<T>> Function(InvocationParameters)>('&%=*');
    return ThreadSingleton.background.executeInteractivelyResult<I, T>(function: function, parameters: parameters, onItem: InteractiveSystem.sendItem);
  }

  @override
  Stream<T> executeStream<T>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Stream<T>> Function(InvocationParameters para) function}) {
    // TODO: implement executeStream
    throw UnimplementedError();
  }
}
