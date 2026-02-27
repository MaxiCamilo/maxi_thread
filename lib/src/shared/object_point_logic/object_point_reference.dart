import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/shared/object_point.dart';
import 'package:maxi_thread/src/shared/shared_service.dart';

class FindObjectPoint<T extends Object> with FunctionalityMixin<ObjectPoint<T>> {
  final String name;

  const FindObjectPoint({required this.name});

  @override
  Future<Result<ObjectPoint<T>>> runFuncionality() async {
    final connectionResult = await SharedService.connection();
    if (connectionResult.itsFailure) return connectionResult.cast();

    final service = connectionResult.content;
    final codeResult = await service.executeResult(
      parameters: InvocationParameters.only(name),
      function: (serv, para) => serv.objectPointManager.locateObjectPoint(name: para.first<String>()),
    );
    if (codeResult.itsFailure) return codeResult.cast();

    final code = codeResult.content;
    final thread = await ThreadManager.threadZone.obtainConnectionFromIdentifier(threadIdentifier: code);
    if (thread.itsFailure) return thread.cast();

    final endChannelContent = await service.buildChannel<dynamic, dynamic>(
      parameters: InvocationParameters.list([name]),
      function: (serv, channel, para) => serv.objectPointManager.waitObjectPointFinish<T>(name: para.first<String>()),
    );

    if (endChannelContent.itsFailure) return endChannelContent.cast();

    return _ObjectPointReference<T>(name: name, code: code, sharedServiceConnection: service, threadConnection: thread.content, endChannel: endChannelContent.content).asResultValue();
  }
}

class _ObjectPointReference<T extends Object> with DisposableMixin, LifecycleHub implements ObjectPoint<T> {
  final String name;
  final int code;
  final Channel endChannel;

  final EntityThreadConnection<SharedService> sharedServiceConnection;
  final ThreadConnection threadConnection;

  static const String _kFunctionName = '&%¡!Mx.ObjRef"*';
  static const String _kObjectName = '&%¡!Mx.ObjName"*';

  _ObjectPointReference({required this.name, required this.code, required this.sharedServiceConnection, required this.threadConnection, required this.endChannel}) {
    createDependency(threadConnection);
    createDependency(endChannel);
  }

  @override
  FutureResult<Channel<S, R>> buildChannel<R, S>({
    InvocationParameters parameters = InvocationParameters.empty,
    required FutureOr<Result<void>> Function(T serv, Channel<R, S> channel, InvocationParameters para) function,
  }) {
    return threadConnection.buildChannel<R, S>(
      parameters: InvocationParameters.addParameters(original: parameters, namedParameters: {_kFunctionName: function, _kObjectName: name}),
      function: _buildChannelOnThread<T, R, S>,
    );
  }

  static FutureResult<void> _buildChannelOnThread<T extends Object, R, S>(Channel<R, S> channel, InvocationParameters parameters) async {
    final name = parameters.named<String>(_kObjectName);
    final func = parameters.named<FutureOr<Result<void>> Function(T serv, Channel<R, S> channel, InvocationParameters para)>(_kFunctionName);

    final itemResult = ThreadManager.threadZone.obtainThreadObject<T>(name: name);
    if (itemResult.itsFailure) return itemResult.cast();

    return await func(itemResult.content, channel, parameters);
  }

  @override
  Future<Result<R>> execute<R>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<R> Function(T serv, InvocationParameters para) function}) {
    return threadConnection.execute<R>(
      parameters: InvocationParameters.addParameters(original: parameters, namedParameters: {_kFunctionName: function, _kObjectName: name}),
      function: _buildExecuteOnThread<T, R>,
    );
  }

  static Future<R> _buildExecuteOnThread<T extends Object, R>(InvocationParameters parameters) async {
    final name = parameters.named<String>(_kObjectName);
    final func = parameters.named<FutureOr<R> Function(T serv, InvocationParameters para)>(_kFunctionName);

    final itemResult = ThreadManager.threadZone.obtainThreadObject<T>(name: name);
    if (itemResult.itsFailure) throw itemResult.error;

    return await func(itemResult.content, parameters);
  }

  @override
  Future<Result<R>> executeResult<R>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<R>> Function(T serv, InvocationParameters para) function}) {
    return threadConnection.executeResult<R>(
      parameters: InvocationParameters.addParameters(original: parameters, namedParameters: {_kFunctionName: function, _kObjectName: name}),
      function: _buildExecuteResultOnThread<T, R>,
    );
  }

  static FutureResult<R> _buildExecuteResultOnThread<T extends Object, R>(InvocationParameters parameters) async {
    final name = parameters.named<String>(_kObjectName);
    final func = parameters.named<FutureOr<Result<R>> Function(T serv, InvocationParameters para)>(_kFunctionName);

    final itemResult = ThreadManager.threadZone.obtainThreadObject<T>(name: name);
    if (itemResult.itsFailure) return itemResult.cast();

    return await func(itemResult.content, parameters);
  }

  @override
  FutureResult<void> claimProvider({required T item}) async {
    return voidResult;
  }

  @override
  FutureResult<void> releaseProvider() async {
    dispose();
    return voidResult;
  }

  @override
  void performObjectDiscard() {
    super.performObjectDiscard();
    /*
    sharedServiceConnection
        .execute(function: (serv, para) => serv.objectPointManager.declareSupplierClosed(code: para.first<int>()))
        .logIfFails(errorName: 'ObjectPointReference -> performObjectDiscard: Failed to notify supplier closure');*/
  }
}
