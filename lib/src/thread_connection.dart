import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

abstract interface class ThreadConnection implements Disposable {
  int get identifier;
  String get name;
  Future<Result<T>> execute<T>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<T> Function(InvocationParameters para) function});
  Future<Result<T>> executeResult<T>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<T>> Function(InvocationParameters para) function});
  FutureResult<void> requestClosure();
}
