import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:meta/meta.dart';

abstract interface class AnonymousEntityThread<T extends Object> implements EntityThreadConnection<T> {
  ThreadConnection get connection;

  @internal
  factory AnonymousEntityThread.rawCreation({required ThreadConnection connection}) = _AnonymousEntityThread<T>;
}

class _AnonymousEntityThread<T extends Object> implements AnonymousEntityThread<T> {
  @override
  final ThreadConnection connection;

  _AnonymousEntityThread({required this.connection});

  @override
  FutureResult<Channel<S, R>> buildChannel<R, S>({
    InvocationParameters parameters = InvocationParameters.empty,
    required FutureOr<Result<void>> Function(T serv, Channel<R, S> channel, InvocationParameters para) function,
  }) {
    return connection.buildChannel(
      parameters: InvocationParameters.addParameters(original: parameters, fixedParameters: [function]),
      function: _buildChannelOnThread<T, R, S>,
    );
  }

  static FutureResult<void> _buildChannelOnThread<T, R, S>(Channel<R, S> channel, InvocationParameters para) async {
    final entityResult = threadSystem.getThreadEntity<T>();
    if (entityResult.itsFailure) {
      return entityResult.cast();
    }

    final entity = entityResult.content;
    final function = para.last<FutureOr<Result<void>> Function(T serv, Channel<R, S> channel, InvocationParameters para)>();

    return await function(entity, channel, para);
  }

  @override
  Future<Result<R>> execute<R>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<R> Function(T serv, InvocationParameters para) function}) {
    return connection.execute(
      parameters: InvocationParameters.addParameters(original: parameters, fixedParameters: [function]),
      function: _executeOnThread<T, R>,
    );
  }

  static Future<R> _executeOnThread<T, R>(InvocationParameters para) async {
    final entityResult = threadSystem.getThreadEntity<T>();
    if (entityResult.itsFailure) {
      throw entityResult;
    }

    final entity = entityResult.content;
    final function = para.last<FutureOr<R> Function(T serv, InvocationParameters para)>();

    return await function(entity, para);
  }

  @override
  Future<Result<R>> executeResult<R>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<R>> Function(T serv, InvocationParameters para) function}) {
    return connection.executeResult(
      parameters: InvocationParameters.addParameters(original: parameters, fixedParameters: [function]),
      function: _executeResultOnThread<T, R>,
    );
  }

  static Future<Result<R>> _executeResultOnThread<T, R>(InvocationParameters para) async {
    final entityResult = threadSystem.getThreadEntity<T>();
    if (entityResult.itsFailure) {
      return entityResult.cast();
    }

    final entity = entityResult.content;
    final function = para.last<FutureOr<Result<R>> Function(T serv, InvocationParameters para)>();

    return await function(entity, para);
  }
}
