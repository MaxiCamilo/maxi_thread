import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

class IsolatedThreadFunctionPack<I, T> {
  final InvocationParameters parameters;
  final FutureOr<Result<T>> Function(InvocationParameters parameters) functionality;

  const IsolatedThreadFunctionPack({required this.parameters, required this.functionality});

  Future<Result<T>> execute({required void Function(I) onItem}) {
    return InteractiveSystem.execute(function: () => functionality(parameters), onItem: onItem);
  }
}
