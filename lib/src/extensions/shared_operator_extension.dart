import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';

extension SharedOperatorMutexExtension on SharedOperator<Mutex> {
  FutureResult<T> enqueueFunctionality<T>(Functionality<T> functionality) {
    return executeResult(parameters: InvocationParameters.only(functionality), function: (oper, para) => oper.executeResult(() => para.first<Functionality<T>>().execute()));
  }

  Future<Result<R>> enqueueResult<R>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<R>> Function(InvocationParameters para) function}) {
    return executeResult(parameters: parameters, function: (oper, para) => oper.executeResult(() => function(para)));
  }
}
