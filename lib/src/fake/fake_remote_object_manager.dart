import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';

class FakeRemoteObjectManager implements ThreadRemoteObjectManager {
  final _objectMap = <Symbol, LocalPointer>{};

  @override
  Future<bool> hasRemoteObject<T>({required Symbol name}) async => _objectMap.containsKey(name);

  @override
  Future<Result<RemoteObject<T>>> deployObject<T>({required Symbol name, required T item}) async {
    final object = _objectMap[name];
    if (object == null) {
      final newRemoteObject = LocalPointer<T>(item: item);
      _objectMap[name] = newRemoteObject;
      return newRemoteObject.asResultValue();
    } else {
      return NegativeResult.controller(
        code: ErrorCode.invalidProperty,
        message: FlexibleOration(message: 'Remote object %1 cannot be instantiated since another object with the same name exists', textParts: [name]),
      );
    }
  }

  @override
  Future<Result<RemoteObject<T>>> obtainObject<T>({required Symbol name}) async {
    final object = _objectMap[name];
    if (object == null) {
      return NegativeResult.controller(
        code: ErrorCode.nonExistent,
        message: FlexibleOration(message: 'Remote object %1 has not been defined', textParts: [name]),
      );
    }

    if (object is RemoteObject<T>) {
      return object.asResultValue<RemoteObject<T>>();
    } else {
      return NegativeResult.controller(
        code: ErrorCode.wrongType,
        message: FlexibleOration(message: 'Remote object %1 is of type %2, but expected to be %3', textParts: [name, object.runtimeType, T]),
      );
    }
  }
}
