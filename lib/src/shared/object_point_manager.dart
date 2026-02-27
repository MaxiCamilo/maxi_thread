import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';

class _ObjectPointInstance with DisposableMixin {
  final String name;
  final ThreadConnection connection;
  final Type type;
  final int code;

  _ObjectPointInstance({required this.name, required this.connection, required this.type, required this.code});

  @override
  void performObjectDiscard() {}
}

class ObjectPointManager with DisposableMixin, LifecycleHub {
  final _references = <_ObjectPointInstance>[];

  int _lastCode = 1;

  static Result<T> obtainProviderObject<T extends Object>({required String name}) {
    final thread = ThreadManager.threadZone;
    final nameMap = '&ObjRed.$name';

    return thread.obtainThreadObject<T>(name: nameMap);
  }

  static Result<void> assignProviderObject<T extends Object>({required String name, required T item}) {
    final thread = ThreadManager.threadZone;
    final nameMap = '&ObjRed.$name';

    final exists = thread.hasThreadObject<T>(name: nameMap);
    if (exists.itsFailure) return exists.cast();
    if (exists.content) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'An object point provider with name %1 already exists', textParts: [name]),
      );
    }

    return thread.defineThreadObject<T>(name: nameMap, object: item);
  }

  static Result<void> removeProviderObject<T extends Object>({required String name}) {
    final thread = ThreadManager.threadZone;
    final nameMap = '&ObjRed.$name';

    final exists = thread.hasThreadObject<T>(name: nameMap);
    if (exists.itsFailure) return exists.cast();
    if (exists.content == false) {
      return voidResult;
    }

    return thread.removeThreadObject<T>(name: nameMap);
  }

  FutureResult<int> defineObjectPoint<T>({required String name}) async {
    final item = _references.selectItem((x) => x.name == name);
    if (item != null) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'An object point instance with name %1 already exists', textParts: [name]),
      );
    }

    final connection = ThreadConnection.threadZone;
    final code = _lastCode;
    _lastCode += 1;

    final instance = _ObjectPointInstance(name: name, connection: connection, type: T, code: code);
    _references.add(instance);
    instance.onDispose.whenComplete(() => _references.remove(instance));

    return code.asResultValue();
  }

  Result<int> locateObjectPoint<T>({required String name}) {
    final item = _references.selectItem((x) => x.name == name);
    if (item == null) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'No object point instance with name %1 exists', textParts: [name]),
      );
    }

    if (item.type != T) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'The object point instance with name %1 is of type %2, not %3', textParts: [name, item.type, T]),
      );
    }

    return ResultValue(content: item.code);
  }

  Result<bool> hasProvider<T>({required String name}) {
    final item = _references.selectItem((x) => x.name == name);
    if (item == null) {
      return false.asResultValue();
    }

    if (item.type != T) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'The object point instance with name %1 is of type %2, not %3', textParts: [name, item.type, T]),
      );
    }

    return true.asResultValue();
  }

  FutureResult<void> waitObjectPointFinish<T>({required String name}) async {
    final item = _references.selectItem((x) => x.name == name && x.type == T);
    if (item == null) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'No object point instance with name %1 and type %2 exists', textParts: [name, T]),
      );
    }

    await item.onDispose;
    return voidResult;
  }

  void declareSupplierClosed({required int code}) {
    _references.selectItem((x) => x.code == code)?.dispose();
  }

  @override
  void performObjectDiscard() {
    super.performObjectDiscard();

    _references.lambda((x) => x.dispose());
    _references.clear();
  }
}
