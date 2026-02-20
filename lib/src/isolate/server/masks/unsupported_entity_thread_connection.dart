import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/entity_thread_connection.dart';

/// An implementation of the `EntityThreadConnection` interface that represents an unsupported connection for a specific service type. This class is designed to provide a way to handle cases where a service has not been mounted or is not available, allowing for graceful error handling when attempts are made to execute functions on an unsupported service. The methods in this class return negative results indicating that the service is not supported, providing clear feedback to the caller about the unavailability of the service and preventing attempts to execute functions on an unsupported connection. This implementation is useful for scenarios where certain services may not be available in the current context, allowing for effective error handling and communication about the unsupported nature of the connection while ensuring that operations are not performed on unsupported services.
class UnsupportedEntityThreadConnection<T> implements EntityThreadConnection<T> {
  const UnsupportedEntityThreadConnection();

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

  @override
  FutureResult<Channel<S, R>> buildChannel<R, S>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<Channel<R, S>>> Function(T serv, InvocationParameters para) function}) async {
    return NegativeResult.controller(
      code: ErrorCode.implementationFailure,
      message: FlexibleOration(message: 'The service %1 has not been mounted', textParts: [T.toString()]),
    );
  }
}
