import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';

class ThreadObjectReference<T> with AsynchronouslyInitializedMixin implements RemoteObject<T> {
  final Symbol name;
  final ThreadInvocator invocator;

  late StreamController<T> _notifyChangeController;

  ThreadObjectReference({required this.name, required this.invocator});

  @override
  Stream<T> get notifyChange async* {
    final itsInit = await initialize().logIfFails(errorName: '[ThreadObjectReference<$T>] Initialization error');
    if (itsInit.itsFailure) {
      throw itsInit;
    }

    yield* _notifyChangeController.stream;
  }

  @override
  Future<Result<void>> performInitialize() async {
    final hasObject = await invocator.executeResult(parameters: InvocationParameters.only(name), function: _checkExists<T>);
    if (!hasObject.content) {
      return NegativeResult.controller(
        code: ErrorCode.nonExistent,
        message: FlexibleOration(message: 'The thread does not contain the remote object %1', textParts: [name]),
      );
    }

    final stream = invocator.executeStream(parameters: InvocationParameters.only(name), function: _getSteamOnThread<T>);

    heart.joinStreamSubscription(
      stream.listen((x) {
        _notifyChangeController.add(x);
      }, onDone: dispose),
    );

    _notifyChangeController = StreamController<T>.broadcast();
    return voidResult;
  }

  static Future<Result<Stream<T>>> _getSteamOnThread<T>(InvocationParameters parameters) {
    return ThreadInstance.getIsolatedInstance().onCorrectFuture((x) => x.remoteObjects.obtainObject<T>(name: parameters.firts<Symbol>())).onCorrectFuture((x) => x.notifyChange.asResultValue<Stream<T>>());
  }

  static Future<Result<bool>> _checkExists<T>(InvocationParameters para) async {
    final isolateInstance = ThreadInstance.getIsolatedInstance();
    if (isolateInstance.itsFailure) return isolateInstance.cast();

    return await isolateInstance.content.remoteObjects.hasRemoteObject<T>(name: para.firts<Symbol>()).toFutureResult();
  }

  @override
  Future<Result<R>> execute<R>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<R> Function(T item, InvocationParameters para) function}) {
    return invocator.executeResult<R>(
      parameters: InvocationParameters.addParameters(original: parameters, namedParameters: {'%%#"!!?¡¡': function}),
      function: _executeOnThread<T, R>,
    );
  }

  static Future<Result<R>> _executeOnThread<T, R>(InvocationParameters para) async {
    final function = para.named<FutureOr<R> Function(T, InvocationParameters)>('%%#"!!?¡¡');

    final item = await ThreadInstance.getIsolatedInstance().onCorrectFuture((x) => x.remoteObjects.obtainObject<T>(name: para.firts<Symbol>())).onCorrectFuture((x) => x.getItem());
    if (item.itsFailure) return item.cast();

    return await function(item.content, para).asResCatchException();
  }

  @override
  Future<Result<R>> executeResult<R>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Result<R>> Function(T item, InvocationParameters para) function}) {
    return invocator.executeResult<R>(
      parameters: InvocationParameters.addParameters(original: parameters, namedParameters: {'%%#"!!?¡¡': function}),
      function: _executeResultOnThread<T, R>,
    );
  }

  static Future<Result<R>> _executeResultOnThread<T, R>(InvocationParameters para) async {
    final function = para.named<FutureOr<Result<R>> Function(T, InvocationParameters)>('%%#"!!?¡¡');

    final item = await ThreadInstance.getIsolatedInstance().onCorrectFuture((x) => x.remoteObjects.obtainObject<T>(name: para.firts<Symbol>())).onCorrectFuture((x) => x.getItem());
    if (item.itsFailure) return item.cast();

    return await function(item.content, para);
  }

  @override
  Future<Result<T>> getItem() {
    return invocator.executeResult(parameters: InvocationParameters.only(name), function: _getItemOnThread<T>);
  }

  static Future<Result<T>> _getItemOnThread<T>(InvocationParameters para) {
    return ThreadInstance.getIsolatedInstance().onCorrectFuture((x) => x.remoteObjects.obtainObject<T>(name: para.firts<Symbol>())).onCorrectFuture((x) => x.getItem());
  }
}
