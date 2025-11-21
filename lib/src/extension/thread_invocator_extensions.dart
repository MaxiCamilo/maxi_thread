import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';

extension ThreadInvocatorExtensions on ThreadInvocator {
  Future<Result<T>> executeTextable<T>({InvocationParameters parameters = InvocationParameters.emptry, required void Function(Oration text) onText, required FutureOr<T> Function(InvocationParameters para) function}) =>
      InteractiveSystem.catchItems<Oration, Result<T>>(
        onItem: onText,
        function: () => execute<T>(parameters: parameters, function: function),
      );

  Future<Result<T>> executeTextableResult<I, T>({
    InvocationParameters parameters = InvocationParameters.emptry,
    required void Function(I text) onText,
    required FutureOr<Result<T>> Function(InvocationParameters para) function,
  }) => InteractiveSystem.catchItems<I, Result<T>>(
    onItem: onText,
    function: () => executeResult<T>(parameters: parameters, function: function),
  );


  
}
