import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/isolated/logic/obtain_thread_identifier.dart';
import 'package:maxi_thread/src/isolated/remote/thread_object_reference.dart';

class IsolateThreadRemoteObject implements ThreadRemoteObjectManager {
  final ThreadInvocator? server;

  final _localValues = <Symbol, LocalPointer>{};
  final _externalValues = <Symbol, ThreadObjectReference>{};

  IsolateThreadRemoteObject({this.server});

  @override
  Future<bool> hasRemoteObject<T>({required Symbol name}) async {
    final actual = _localValues[name];
    if (actual == null) {
      if (server == null) {
        return false;
      } else {
        return (await server!.execute(parameters: InvocationParameters.only(name), function: _hasRemoteObjectOnServer<T>)).content;
      }
    } else {
      return true;
    }
  }

  @override
  Future<Result<RemoteObject<T>>> deployObject<T>({required Symbol name, required T item}) async {
    if (await hasRemoteObject<T>(name: name)) {
      return NegativeResult.controller(
        code: ErrorCode.nonExistent,
        message: FlexibleOration(message: 'The remote object %1 is already instantiated', textParts: [name]),
      );
    }

    if (server != null) {
      final serverInstanceResult = await server!.executeResult(parameters: InvocationParameters.only(name), function: _deployObjectOnServer<T>);
      if (serverInstanceResult.itsFailure) return serverInstanceResult.cast();
    }

    final newPoint = LocalPointer<T>(item: item);
    _localValues[name] = newPoint;

    return newPoint.asResultValue<RemoteObject<T>>();
  }

  static Result<void> _deployObjectOnServer<T>(InvocationParameters parameters) {
    return ThreadInstance.getIsolatedInstance()
        .select((x) => x.remoteObjects)
        .cast<IsolateThreadRemoteObject>()
        .includeResult((x) => ThreadInvocator.getOriginThread())
        .onCorrect((x) => x.$1._reservePoint<T>(name: parameters.firts<Symbol>(), invocator: x.$2));
  }

  @override
  Future<Result<RemoteObject<T>>> obtainObject<T>({required Symbol name}) async {
    final exists = _localValues[name];
    if (exists != null) {
      if (exists is RemoteObject<T>) {
        return exists.asResultValue().cast<RemoteObject<T>>();
      } else {
        return NegativeResult.controller(
          code: ErrorCode.wrongType,
          message: FlexibleOration(message: 'The object pointer %1 is %2, a type %3 was expected', textParts: [name, exists.runtimeType, T]),
        );
      }
    }

    if (server == null) {
      return NegativeResult.controller(
        code: ErrorCode.nonExistent,
        message: FlexibleOration(message: 'The remote object %1 has not been created', textParts: [name]),
      );
    }

    final idResult = await server!.executeResult<int>(parameters: InvocationParameters.only(name), function: _obtainIDThread<T>);
    if (idResult.itsFailure) return idResult.cast();

    // final threadFlag = await server!.executeFunctionality(functionality: SearchPointOnThreadServer(identifier: idResult.content));
    //if (threadFlag.itsFailure) return threadFlag.cast();

    final threadConnection = await ThreadInstance.getIsolatedInstance().cast<IsolatedThread>().onCorrectFuture((x) => x.getInvocatorByID(identifier: idResult.content));
    if (threadConnection.itsFailure) return threadConnection.cast();

    final remote = ThreadObjectReference<T>(name: name, invocator: threadConnection.content);
    _externalValues[name] = remote;

    return remote.asResultValue();
  }

  static Future<Result<int>> _obtainIDThread<T>(InvocationParameters parameters) {
    return ThreadInstance.getIsolatedInstance()
        .select((x) => x.remoteObjects)
        .cast<IsolateThreadRemoteObject>()
        .onCorrectFuture((x) => x.obtainObject<T>(name: parameters.firts<Symbol>()))
        .castFuture<ThreadObjectReference<T>>()
        .selectFuture((x) => x.invocator)
        .onCorrectFuture((x) => x.executeFunctionality(functionality: const ObtainThreadIdentifier()));
  }

  Result<void> _reservePoint<T>({required Symbol name, required ThreadInvocator invocator}) {
    assert(server == null);

    final exist = _localValues.containsKey(name) || _externalValues.containsKey(name);
    if (exist) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'The remote object %1 has already been instantiated', textParts: [name]),
      );
    }

    final newPointer = ThreadObjectReference<T>(name: name, invocator: invocator);
    _externalValues[name] = newPointer;

    return voidResult;
  }

  static Future<bool> _hasRemoteObjectOnServer<T>(InvocationParameters parameters) async {
    return (await ThreadInstance.getIsolatedInstance().onCorrectFuture((x) => x.remoteObjects.hasRemoteObject<T>(name: parameters.firts<Symbol>()).toFutureResult())).content;
  }
}
