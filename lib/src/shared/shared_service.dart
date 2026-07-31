import 'dart:async';
import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/shared/shared_events_manager.dart';
import 'package:rxdart/rxdart.dart';

class SharedService with DisposableMixin, LifecycleHub, InitializableMixin {
  late Map<String, Object> _sharedObjectMap;
  late Map<String, Mutex> _sharedMutexMap;
  late SharedEventsManager eventManager;

  late StreamController<(String, Object)> _objectChangeController;

  late Map<String, (int, int, Type, TinyEvent)> _sharedOperators;

  static FutureResult<EntityThreadConnection<SharedService>> connection() async {
    await Future.delayed(Duration.zero);
    return await threadSystem.createEntityThread<SharedService>(instance: SharedService(), omitIfExists: true);
  }

  @override
  Result<void> performInitialization() {
    _sharedObjectMap = <String, Object>{};
    eventManager = lifecycleScope.joinDisposableObject(SharedEventsManager());
    _objectChangeController = lifecycleScope.joinStreamController(StreamController<(String, Object)>.broadcast());
    _sharedOperators = <String, (int, int, Type, TinyEvent)>{};
    _sharedMutexMap = <String, Mutex>{};
    return voidResult;
  }

  bool hasObject<T>({required String name}) {
    return _sharedObjectMap[name] is T;
  }

  Result<T> obtainSharedObject<T>({required String name, T? defaultValue}) {
    final item = _sharedObjectMap[name];
    if (item == null) {
      if (defaultValue != null) {
        _sharedObjectMap[name] = defaultValue;
        return defaultValue.asResultValue();
      }
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'No object of type %1 is registered with the name %2', textParts: [T, name]),
      );
    }

    if (item is T) {
      return (item as T)!.asResultValue();
    } else {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'The object registered with the name %1 is not of type %2', textParts: [name, T]),
      );
    }
  }

  Result<void> removeSharedObject({required String name}) {
    final exists = _sharedObjectMap[name];
    if (exists != null) {
      _sharedObjectMap.remove(name);
      if (exists is Disposable) {
        exists.dispose();
      }
    }

    return voidResult;
  }

  FutureResult<R> executeSharedObject<T, R>({required String name, InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<R>> Function(T serv, InvocationParameters para) function}) async {
    final item = _sharedObjectMap[name];
    if (item == null) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'No object of type %1 is registered with the name %2', textParts: [T, name]),
      );
    }

    if (item is T) {
      return await function(item as T, parameters);
    } else {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'The object registered with the name %1 is not of type %2', textParts: [name, T]),
      );
    }
  }

  Result<void> registerObject<T extends Object>({required String name, required T item, bool removePrevious = true}) {
    final exists = _sharedObjectMap[name];
    if (exists != null) {
      if (removePrevious) {
        _sharedObjectMap.remove(name);
        if (exists is Disposable) {
          exists.dispose();
        }
      } else {
        return NegativeResult.controller(
          code: ErrorCode.invalidFunctionality,
          message: FlexibleOration(message: 'An object of type %1 is already registered with the name %2', textParts: [T, name]),
        );
      }
    }

    _sharedObjectMap[name] = item;
    _objectChangeController.add((name, item));

    return voidResult;
  }

  FutureResult<void> observerChannel<T>({required String name, required Channel<dynamic, T> channel}) async {
    final stream = _objectChangeController.stream.where((change) => change.$1 == name).map((change) => change.$2).whereType<T>();
    final subscription = stream.listen(
      (item) {
        channel.sendItem(item);
      },
      onError: (x, y) {
        log('Error in shared service observer channel for object $name: $x, stackTrace: $y', name: 'SharedService.observerChannel');
      },
      onDone: () => channel.dispose(),
    );

    await channel.onDispose.toFuture();
    subscription.cancel();
    return voidResult;
  }

  Result<bool> isOperatorRegistered({required String name, required Type operatorType}) {
    final exists = _sharedOperators[name];
    if (exists == null) return false.asResultValue();

    if (exists.$3 != operatorType) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'An operator with the name %1 is already registered but with a different type (%2)', textParts: [name, exists.$3]),
      );
    }
    return true.asResultValue();
  }

  Result<void> registerOperator({required String name, required int operatorId, required Type operatorType, bool removePrevious = true}) {
    final exists = _sharedOperators[name];
    if (exists != null) {
      if (removePrevious) {
        _sharedOperators.remove(name);
      } else {
        return NegativeResult.controller(
          code: ErrorCode.invalidFunctionality,
          message: FlexibleOration(message: 'An operator with the name %1 is already registered', textParts: [name]),
        );
      }
    }

    final onDispose = ThreadConnection.threadZone.onDispose.whenComplete(() => _sharedOperators.remove(name));

    _sharedOperators[name] = (ThreadConnection.threadZone.identifier, operatorId, operatorType, onDispose);
    return voidResult;
  }

  Result<(int, int)> obtainOperatorAddress({required String name, required Type operatorType}) {
    final exists = _sharedOperators[name];
    if (exists == null) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'No operator is registered with the name %1', textParts: [name]),
      );
    }

    if (exists.$3 != operatorType) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'The operator registered with the name %1 is not of the expected type (%2)', textParts: [name, operatorType]),
      );
    }

    return (exists.$1, exists.$2).asResultValue();
  }

  Mutex obtainMutex({required String name}) {
    final exists = _sharedMutexMap[name];
    if (exists != null) {
      return exists;
    }

    final mutex = Mutex();
    _sharedMutexMap[name] = mutex;
    mutex.onDispose.whenComplete(() {
      _sharedMutexMap.remove(name);
    });

    return mutex;
  }

  FutureResult<T> executeMutex<T>({required String name, required FutureOr<Result<T>> Function() function}) {
    final mutex = obtainMutex(name: name);
    return mutex.executeResult<T>(() async {
      if (LifeCoordinator.isZoneHeartCanceled) {
        return CancelationResult();
      }

      return await function();
    });
  }

  void removeOperator({required String name}) {
    final exists = _sharedOperators.remove(name);
    if (exists != null) {
      exists.$4.ignore();
    }
  }

  @override
  void performObjectDiscard() {}
}
