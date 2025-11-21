import 'dart:async';
import 'dart:isolate';

import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/isolated/clients/isolated_service_client_witt_entity.dart';
import 'package:maxi_thread/src/isolated/logic/obtain_send_port.dart';

class IsolatedServiceServerInstance<T> implements ThreadServiceInvocator<T> {
  final ThreadInvocator invocator;

  IsolatedServiceServerInstance({required this.invocator});

  @override
  Type get serviceType => T;

  @override
  bool isCompatible(Type type) => type == T;

  Future<Result<SendPort>> getSendPort() => invocator.executeFunctionality(functionality: const ObtainSendPort());

  @override
  Future<Result<R>> execute<R>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<R> Function(T serv, InvocationParameters para) function}) {
    return invocator.execute(
      parameters: InvocationParameters.addParameters(original: parameters, namedParameters: {'%%&[E]': function}),
      function: _executeOnThread<T, R>,
    );
  }

  static Future<R> _executeOnThread<E, R>(InvocationParameters parameters) async {
    final itsInThread = ThreadInstance.getIsolatedInstance();
    if (itsInThread.itsFailure) throw itsInThread.error;

    final function = parameters.named<FutureOr<R> Function(E, InvocationParameters)>('%%&[E]');

    final itsEntityThread = itsInThread.content.services.asResultValue().cast<IsolatedServiceClientWittEntity<E>>();
    if (itsEntityThread.itsFailure) throw itsEntityThread.error;

    return await function(itsEntityThread.content.entity, parameters);
  }

  @override
  Future<Result<R>> executeResult<R>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Result<R>> Function(T serv, InvocationParameters para) function}) {
    return invocator.executeResult(
      parameters: InvocationParameters.addParameters(original: parameters, namedParameters: {'%%&[E]': function}),
      function: _executeResultOnThread<T, R>,
    );
  }

  static Future<Result<R>> _executeResultOnThread<E, R>(InvocationParameters parameters) async {
    final itsInThread = ThreadInstance.getIsolatedInstance();
    if (itsInThread.itsFailure) return itsInThread.cast();

    final function = parameters.named<FutureOr<Result<R>> Function(E, InvocationParameters)>('%%&[E]');

    final itsEntityThread = itsInThread.content.services.asResultValue().cast<IsolatedServiceClientWittEntity<E>>();
    if (itsEntityThread.itsFailure) return itsEntityThread.cast();

    return await function(itsEntityThread.content.entity, parameters);
  }

  @override
  Stream<R> executeStream<R>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Result<Stream<R>>> Function(T serv, InvocationParameters para) function}) {
    return invocator.executeStream(
      parameters: InvocationParameters.addParameters(original: parameters, namedParameters: {'%%&[E]': function}),
      function: _executeStreamOnThread<T, R>,
    );
  }

  static FutureOr<Result<Stream<R>>> _executeStreamOnThread<E, R>(InvocationParameters parameters) async {
    final itsInThread = ThreadInstance.getIsolatedInstance();
    if (itsInThread.itsFailure) return itsInThread.cast();

    final function = parameters.named<FutureOr<Result<Stream<R>>> Function(E, InvocationParameters)>('%%&[E]');

    final itsEntityThread = itsInThread.content.services.asResultValue().cast<IsolatedServiceClientWittEntity<E>>();
    if (itsEntityThread.itsFailure) return itsEntityThread.cast();

    return await function(itsEntityThread.content.entity, parameters);
  }
}
