import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/entity_thread_connection.dart';

class UnsupportedEntityThreadConnection<T> implements EntityThreadConnection<T> {
  @override
  Future<Result<R>> execute<R>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<R> Function(T serv, InvocationParameters para) function}) async {
    return NegativeResult.controller(
      code: ErrorCode.implementationFailure,
      message: FlexibleOration(message: 'The service %1 has not been mounted', textParts: [T.toString()]),
    );
  }

  @override
  Future<Result<R>> executeResult<R>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<R>> Function(T serv, InvocationParameters para) function}) async {
    return NegativeResult.controller(
      code: ErrorCode.implementationFailure,
      message: FlexibleOration(message: 'The service %1 has not been mounted', textParts: [T.toString()]),
    );
  }
}
