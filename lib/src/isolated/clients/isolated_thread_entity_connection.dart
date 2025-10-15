import 'dart:async';

import 'dart:isolate';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/isolated/channels/isolator_channel_end_point.dart';
import 'package:maxi_thread/src/isolated/connections/isolated_thread_connection.dart';

class IsolatedThreadEntityConnection<E extends Object> with AsynchronouslyInitializedMixin implements ThreadInvocator, IsolatedThread {
  final IsolatedThreadConnection serverConnection;

  Type get entityType => E;

  late IsolatedThreadConnection _connection;

  IsolatedThreadEntityConnection({required this.serverConnection});

  @override
  Future<Result<void>> performInitialize() async {
    final pointResult = await serverConnection.executeResult(function: _getEntityPoint<E>);
    if (!pointResult.itsCorrect) return pointResult.cast();

    _connection = IsolatedThreadConnection(channel: IsolatorChannelEndPoint(sendPoint: pointResult.content));
    return voidResult;
  }

  static Future<Result<SendPort>> _getEntityPoint<E extends Object>(InvocationParameters parameter) {
    return (ThreadSingleton.instance.service<E>() as IsolatedThread).getNewSendPortFromThread();
  }

  @override
  Future<Result<void>> closeThread() async {
    final initializationResult = await initialize();
    if (!initializationResult.itsCorrect) return initializationResult.cast();

    return _connection.closeThread();
  }

  @override
  Future<Result<T>> execute<T>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<T> Function(InvocationParameters para) function}) async {
    final initializationResult = await initialize();
    if (!initializationResult.itsCorrect) return initializationResult.cast();

    return _connection.execute<T>(parameters: parameters, function: function);
  }

  @override
  Future<Result<T>> executeResult<T>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Result<T>> Function(InvocationParameters para) function}) async {
    final initializationResult = await initialize();
    if (!initializationResult.itsCorrect) return initializationResult.cast();

    return _connection.executeResult<T>(parameters: parameters, function: function);
  }

  @override
  Future<Result<T>> executeInteractively<I, T>({
    InvocationParameters parameters = InvocationParameters.emptry,
    required FutureOr<T> Function(InvocationParameters para) function,
    required void Function(I p1) onItem,
  }) async {
    final initializationResult = await initialize();
    if (!initializationResult.itsCorrect) return initializationResult.cast();

    return await _connection.executeInteractively<I, T>(parameters: parameters, function: function, onItem: onItem);
  }

  @override
  Future<Result<T>> executeInteractivelyResult<I, T>({
    InvocationParameters parameters = InvocationParameters.emptry,
    required FutureOr<Result<T>> Function(InvocationParameters para) function,
    required void Function(I p1) onItem,
  }) async {
    final initializationResult = await initialize();
    if (!initializationResult.itsCorrect) return initializationResult.cast();

    return await _connection.executeInteractivelyResult<I, T>(parameters: parameters, function: function, onItem: onItem);
  }

  @override
  Stream<T> executeStream<T>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Stream<T>> Function(InvocationParameters para) function}) async* {
    final initializationResult = await initialize();
    if (!initializationResult.itsCorrect) throw initializationResult.error;

    yield* _connection.executeStream<T>(parameters: parameters, function: function);
  }

  @override
  Future<Result<SendPort>> getNewSendPortFromThread() async {
    final initializationResult = await initialize();
    if (!initializationResult.itsCorrect) return initializationResult.cast();

    return _connection.getNewSendPortFromThread();
  }

  @override
  void performObjectDiscard(bool itsWasInitialized) {
    if (itsWasInitialized) {
      _connection.dispose();
    }
  }
}
