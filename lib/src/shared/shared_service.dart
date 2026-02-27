import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/shared/object_point_manager.dart';
import 'package:maxi_thread/src/shared/shared_events_manager.dart';

class SharedService with DisposableMixin, LifecycleHub, InitializableMixin {
  late List<Object> _objectsList;
  late SharedEventsManager eventManager;
  late ObjectPointManager objectPointManager;

  static FutureResult<EntityThreadConnection<SharedService>> connection() {
    return threadSystem.createEntityThread<SharedService>(instance: SharedService(), omitIfExists: true);
  }

  static FutureResult<R> callSharedObject<T, R>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<R>> Function(T serv, InvocationParameters para) function}) {
    return connection().onCorrectFuture(
      (x) => x.executeResult(
        parameters: parameters,
        function: (item, para) => item.executeSharedObject<T, R>(function: function),
      ),
    );
  }

  static FutureResult<T> cloneSharedObject<T>() {
    return callSharedObject<T, T>(function: (serv, para) => ResultValue(content: serv));
  }

  @override
  Result<void> performInitialization() {
    _objectsList = <Object>[];
    eventManager = joinDisposableObject(SharedEventsManager());
    objectPointManager = joinDisposableObject(ObjectPointManager());
    return voidResult;
  }

  bool hasObject<T>() {
    return _objectsList.whereType<T>().firstOrNull != null;
  }

  FutureResult<R> executeSharedObject<T, R>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<R>> Function(T serv, InvocationParameters para) function}) async {
    final item = _objectsList.whereType<T>().firstOrNull;
    if (item == null) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'No object of type %1 is registered', textParts: [T]),
      );
    }

    return await function(item, parameters);
  }

  Result<void> registerObject<T extends Object>({required T item, bool removePrevious = true}) {
    final exists = _objectsList.whereType<T>().firstOrNull;
    if (exists != null) {
      if (removePrevious) {
        _objectsList.remove(exists);
        if (exists is Disposable) {
          (exists as Disposable).dispose();
        }
      } else {
        return NegativeResult.controller(
          code: ErrorCode.invalidFunctionality,
          message: FlexibleOration(message: 'An object of type %1 is already registered', textParts: [T]),
        );
      }
    }

    _objectsList.add(item);

    return voidResult;
  }
}
