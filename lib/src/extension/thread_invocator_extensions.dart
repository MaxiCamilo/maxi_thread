import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';

extension ThreadInvocatorExtensions on ThreadInvocator {
  Future<Result<T>> executeTextable<T>({InvocationParameters parameters = InvocationParameters.emptry, required void Function(Oration text) onText, required FutureOr<T> Function(InvocationParameters para) function}) =>
      executeInteractively<Oration, T>(onItem: onText, function: function, parameters: parameters);

  Future<Result<T>> executeTextableResult<I, T>({
    InvocationParameters parameters = InvocationParameters.emptry,
    required void Function(I text) onText,
    required FutureOr<Result<T>> Function(InvocationParameters para) function,
  }) => executeInteractivelyResult(onItem: onText, function: function, parameters: parameters);
}
