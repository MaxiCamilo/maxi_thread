import 'dart:async';
import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:rxdart/rxdart.dart';

class IsolateStreamManager with DisposableMixin {
  final ThreadInstance parent;

  final _externalStreams = <int, StreamController>{};
  final _internalStreams = <int, StreamSubscription>{};

  IsolateStreamManager({required this.parent});

  int _lastID = 0;

  Future<Result<Stream<T>>> executeStream<T>({required ThreadInvocator origin, required InvocationParameters parameters, required FutureOr<Result<Stream<T>>> Function(InvocationParameters para) function}) async {
    final idResult = await origin
        .executeResult(
          function: _executeStreamOnServer,
          parameters: InvocationParameters.addParameters(original: parameters, namedParameters: {'&%/"[]*pqeñ': function}),
        )
        .logIfFails(errorName: 'IsolateStreamManager -> executeStream<$T>');

    if (idResult.itsFailure) return idResult.cast();
    final newController = StreamController<T>();

    _externalStreams[idResult.content] = newController;
    newController.done.whenComplete(() => _externalStreams.remove(idResult.content));

    return newController.stream
        .doOnCancel(() => origin.executeResult(parameters: InvocationParameters.only(idResult.content), function: _cancelOnThread).logIfFails(errorName: 'IsolateStreamManager -> executeStream -> doOnCancel'))
        .asResultValue();
  }

  static Future<Result<int>> _executeStreamOnServer<T>(InvocationParameters parameters) async {
    final invocatorResult = ThreadInvocator.getOriginThread();
    if (invocatorResult.itsFailure) return invocatorResult.cast();

    final function = parameters.named<FutureOr<Result<Stream<T>>> Function(InvocationParameters)>('&%/"[]*pqeñ');
    final threadInstanceResult = ThreadInstance.getIsolatedInstance().cast<IsolatedThread>();
    if (threadInstanceResult.itsFailure) return threadInstanceResult.cast();

    return await threadInstanceResult.content.streamManager.allocateExternalStream(origin: invocatorResult.content, parameters: parameters, function: function);
  }

  static Result<void> _cancelOnThread(InvocationParameters para) {
    final threadInstanceResult = ThreadInstance.getIsolatedInstance().cast<IsolatedThread>();
    if (threadInstanceResult.itsFailure) return threadInstanceResult.cast();

    threadInstanceResult.content.streamManager._closeInternalStream(id: para.firts<int>());
    return voidResult;
  }

  Future<Result<int>> allocateExternalStream<T>({required ThreadInvocator origin, required InvocationParameters parameters, required FutureOr<Result<Stream<T>>> Function(InvocationParameters para) function}) async {
    int id = _lastID;
    _lastID += 1;

    separateExecution(
      function: () async {
        final waiter = Completer<Result<void>>();
        final streamResult = await function(parameters);
        if (streamResult.itsFailure) {
          origin
              .execute(parameters: InvocationParameters.list([id, streamResult, (streamResult is ExceptionResult) ? (streamResult as ExceptionResult).stackTrace : StackTrace.current]), function: _sendErrorOnThread)
              .logIfFails(errorName: 'IsolateStreamManager -> allocateExternalStream -> onCreationError');
        }

        final subscription = streamResult.content
            .whenCancel(onCancel: () => LifeCoordinator.tryGetZoneHeart?.dispose())
            .listen(
              (event) => origin.execute(parameters: InvocationParameters.list([id, event]), function: _sendItemOnThread<T>).logIfFails(errorName: 'IsolateStreamManager -> allocateExternalStream -> onItem'),

              onError: (ex, st) => origin.execute(parameters: InvocationParameters.list([id, ex, st]), function: _sendErrorOnThread).logIfFails(errorName: 'IsolateStreamManager -> allocateExternalStream -> onError'),

              onDone: () async {
                await Future.delayed(Duration.zero);
                _internalStreams.remove(id);
                await origin.execute(parameters: InvocationParameters.only(id), function: _sendFinishedOnThread).logIfFails(errorName: 'IsolateStreamManager -> allocateExternalStream -> onDone');
                await Future.delayed(Duration.zero);
                if (!waiter.isCompleted) {
                  waiter.complete(voidResult);
                }
              },
            );

        LifeCoordinator.zoneHeart.onDispose.whenComplete(() => subscription.cancel());

        _internalStreams[id] = subscription;

        return await waiter.future;
      },
    );

    return id.asResultValue();
  }

  static void _sendItemOnThread<T>(InvocationParameters parameters) {
    ThreadInstance.getIsolatedInstance()
        .cast<IsolatedThread>()
        .onCorrect((x) {
          x.streamManager._receiveItem<T>(id: parameters.firts<int>(), item: parameters.second());
          return voidResult;
        })
        .logIfFails(errorName: 'IsolateStreamManager -> receiveItem<$T>');
  }

  void _receiveItem<T>({required int id, required dynamic item}) {
    final streamController = _externalStreams[id];
    if (streamController == null) {
      //log('[IsolateStreamManager] An item was sent to instance number $id, but it does not exist');
      return;
    }

    if (streamController.isClosed) {
      log('[IsolateStreamManager] An item was sent to instance number $id, but this control was closed');
      return;
    }

    if (streamController is StreamController<T>) {
      streamController.add(item);
    } else {
      log('[IsolateStreamManager] An item was sent to instance number $id, but the type is ${item.runtimeType} and the controller only accepts ${streamController.typeItemSent}');
    }
  }

  static void _sendErrorOnThread(InvocationParameters parameters) => ThreadInstance.getIsolatedInstance()
      .cast<IsolatedThread>()
      .onCorrect((x) {
        x.streamManager._receiveError(id: parameters.firts<int>(), ex: parameters.second(), st: parameters.third<StackTrace>());
        return voidResult;
      })
      .logIfFails(errorName: 'IsolateStreamManager -> receiveError');

  void _receiveError({required int id, required dynamic ex, required StackTrace st}) {
    final streamController = _externalStreams[id];
    if (streamController == null) {
      log('[IsolateStreamManager] An error was sent to instance number $id, but it does not exist');
      return;
    }

    if (streamController.isClosed) {
      log('[IsolateStreamManager] An error was sent to instance number $id, but this control was closed');
      return;
    }

    streamController.addError(ex, st);
  }

  static void _sendFinishedOnThread(InvocationParameters parameters) => ThreadInstance.getIsolatedInstance()
      .cast<IsolatedThread>()
      .onCorrect((x) {
        x.streamManager._receiveFinish(id: parameters.firts<int>());
        return voidResult;
      })
      .logIfFails(errorName: 'IsolateStreamManager -> receiveError');

  void _receiveFinish({required int id}) {
    final streamController = _externalStreams.remove(id);
    if (streamController != null) {
      streamController.close();
    }
  }

  void _closeInternalStream({required int id}) {
    _internalStreams.remove(id)?.cancel();
  }

  @override
  void performObjectDiscard() {
    final internal = _internalStreams.values.toList(growable: false);
    _internalStreams.clear();
    internal.lambda((x) => x.cancel());

    final externalStream = _externalStreams.values.toList(growable: false);
    _externalStreams.clear();
    externalStream.lambda((x) => x.close());
  }
}
