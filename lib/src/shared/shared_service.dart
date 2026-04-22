import 'dart:async';
import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/shared/shared_events_manager.dart';
import 'package:rxdart/rxdart.dart';

class SharedService with DisposableMixin, LifecycleHub, InitializableMixin {
  late Map<String, Object> _sharedObjectMap;
  late SharedEventsManager eventManager;

  late StreamController<(String, Object)> _objectChangeController;

  static FutureResult<EntityThreadConnection<SharedService>> connection() {
    return threadSystem.createEntityThread<SharedService>(instance: SharedService(), omitIfExists: true);
  }

  @override
  Result<void> performInitialization() {
    _sharedObjectMap = <String, Object>{};
    eventManager = lifecycleScope.joinDisposableObject(SharedEventsManager());
    _objectChangeController = lifecycleScope.joinStreamController(StreamController<(String, Object)>.broadcast());
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
  
  @override
  void performObjectDiscard() {
  }
}
