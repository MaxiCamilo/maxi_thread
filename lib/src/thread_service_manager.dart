import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';

abstract interface class ThreadServiceManager {
  Future<Result<bool>> hasService(Type type);

  Result<ThreadServiceInvocator<T>> getServiceInvocator<T extends Object>();
  Future<Result<ThreadServiceInvocator<T>>> createServiceThread<T extends Object>({required T item, bool skipIfAlreadyMounted = true, String? name});
}
