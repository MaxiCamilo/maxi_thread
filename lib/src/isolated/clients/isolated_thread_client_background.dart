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
    final instance = ThreadInstance.getIsolatedInstance();
    if (instance.itsFailure) throw instance.cast();

    final function = parameters.named<FutureOr<T> Function(InvocationParameters)>('&%=*');
    return (await instance.content.background.execute(function: function, parameters: parameters)).content;
  }

  @override
  Future<Result<T>> executeResult<T>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Result<T>> Function(InvocationParameters para) function}) {
    return server.executeResult<T>(function: _executeResult<T>, parameters: InvocationParameters.clone(parameters, avoidConstants: true)..namedParameters['&%=*'] = function);
  }

  static Future<Result<T>> _executeResult<T>(InvocationParameters parameters) async {
    final instance = ThreadInstance.getIsolatedInstance();
    if (instance.itsFailure) return instance.cast();

    final function = parameters.named<FutureOr<Result<T>> Function(InvocationParameters)>('&%=*');
    return instance.content.background.executeResult(function: function, parameters: parameters);
  }

  @override
  Future<Result<T>> executeFunctionality<T>({required Functionality<T> functionality}) {
    return server.executeFunctionality(functionality: functionality);
  }

  @override
  Stream<T> executeStream<T>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Result<Stream<T>>> Function(InvocationParameters para) function}) {
    return server.executeStream<T>(function: function, parameters: parameters);
  }
}
