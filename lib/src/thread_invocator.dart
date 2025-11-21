import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

abstract interface class ThreadInvocator {
  Future<Result<T>> execute<T>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<T> Function(InvocationParameters para) function});
  Future<Result<T>> executeResult<T>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Result<T>> Function(InvocationParameters para) function});

  Stream<T> executeStream<T>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Result<Stream<T>>> Function(InvocationParameters para) function});

  Future<Result<T>> executeFunctionality<T>({required Functionality<T> functionality});

  static const Symbol entitySymbol = #maxiThreadInvocatorEntity;
  static const Symbol originSymbol = #maxiThreadOriginSymbol;

  static Result<T> getEntityThread<T>() {
    final isolated = Zone.current[entitySymbol];
    if (isolated != null && isolated is T) {
      return ResultValue(content: isolated);
    } else {
      return NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: FlexibleOration(message: 'This thread does not manage entity %1', textParts: [T]),
      );
    }
  }

  static Result<ThreadInvocator> getOriginThread() {
    return ResultValue<Object?>(content: Zone.current[originSymbol]).errorIfItsNull<ThreadInvocator>(message: FixedOration(message: 'The source thread has not been defined')).cast<ThreadInvocator>().logIfFails();
  }
}
