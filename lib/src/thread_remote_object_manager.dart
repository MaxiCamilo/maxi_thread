import 'package:maxi_framework/maxi_framework.dart';

abstract interface class ThreadRemoteObjectManager {
  Future<bool> hasRemoteObject<T>({required Symbol name});
  Future<Result<RemoteObject<T>>> deployObject<T>({required Symbol name, required T item});
  Future<Result<RemoteObject<T>>> obtainObject<T>({required Symbol name});
}
