import 'dart:async';
import 'dart:isolate';

import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/isolated/clients/isolated_service_client_witt_entity.dart';
import 'package:maxi_thread/src/isolated/clients/isolated_thread_client.dart';
import 'package:maxi_thread/src/isolated/connections/isolated_thread_connection.dart';
import 'package:maxi_thread/src/isolated/logic/search_service_on_server.dart';

class IsolatedServicesClientConnection<T extends Object> with AsynchronouslyInitializedMixin implements ThreadServiceInvocator<T> {
  final IsolatedThreadClient invocator;
  final ThreadInvocator serverConnection;
  final SendPort? connector;

  late IsolatedThreadConnection _connection;

  IsolatedServicesClientConnection({required this.invocator, required this.serverConnection, required this.connector});

  @override
  Type get serviceType => T;

  @override
  bool isCompatible(Type type) => T == type;

  @override
  Future<Result<void>> performInitialize() async {
    late final SendPort serviceConnection;

    if (connector == null) {
      final servicePortResult = await serverConnection.executeFunctionality(functionality: SearchSendPortServiceOnServer<T>());
      if (servicePortResult.itsFailure) return servicePortResult.cast();

      serviceConnection = servicePortResult.content;
    } else {
      serviceConnection = connector!;
    }

    final newConnection = await invocator.connectPoint(point: serviceConnection);
    if (newConnection.itsFailure) return newConnection.cast();

    _connection = newConnection.content;
    return voidResult;
  }

  @override
  Future<Result<R>> execute<R>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<R> Function(T serv, InvocationParameters para) function}) async {
    final itsInitialized = await initialize();
    if (itsInitialized.itsFailure) return itsInitialized.cast();

    return _connection.execute(
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
  Future<Result<R>> executeResult<R>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Result<R>> Function(T serv, InvocationParameters para) function}) async {
    final itsInitialized = await initialize();
    if (itsInitialized.itsFailure) return itsInitialized.cast();

    return _connection.executeResult(
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
  Stream<R> executeStream<R>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Result<Stream<R>>> Function(T serv, InvocationParameters para) function}) async* {
    final itsInitialized = await initialize();
    if (itsInitialized.itsFailure) throw itsInitialized;

    yield* _connection.executeStream(
      parameters: InvocationParameters.addParameters(original: parameters, namedParameters: {'%%&[E]': function}),
      function: _executeStreamOnThread<T, R>,
    );
  }

  static Future<Result<Stream<R>>> _executeStreamOnThread<E, R>(InvocationParameters parameters) async {
    final itsInThread = ThreadInstance.getIsolatedInstance();
    if (itsInThread.itsFailure) return itsInThread.cast();

    final function = parameters.named<FutureOr<Result<Stream<R>>> Function(E, InvocationParameters)>('%%&[E]');

    final itsEntityThread = itsInThread.content.services.asResultValue().cast<IsolatedServiceClientWittEntity<E>>();
    if (itsEntityThread.itsFailure) return itsEntityThread.cast();

    return await function(itsEntityThread.content.entity, parameters);
  }
}
