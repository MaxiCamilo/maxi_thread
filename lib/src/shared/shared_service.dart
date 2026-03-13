import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/shared/shared_events_manager.dart';

class SharedService with DisposableMixin, LifecycleHub, InitializableMixin {
  late Map<String, Object> _sharedObjectMap;
  late SharedEventsManager eventManager;

  static FutureResult<EntityThreadConnection<SharedService>> connection() {
    return threadSystem.createEntityThread<SharedService>(instance: SharedService(), omitIfExists: true);
  }

  @override
  Result<void> performInitialization() {
    _sharedObjectMap = <String, Object>{};
    eventManager = joinDisposableObject(SharedEventsManager());
    return voidResult;
  }

  bool hasObject<T>({required String name}) {
    return _sharedObjectMap[name] is T;
  }

  Result<T> obtainSharedObject<T>({required String name}) {
    final item = _sharedObjectMap[name];
    if (item == null) {
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

    return voidResult;
  }
}
