import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

class IsolatedThreadFunctionPack<T> {
  final InvocationParameters parameters;
  final FutureOr<Result<T>> Function(InvocationParameters parameters) functionality;

  const IsolatedThreadFunctionPack({required this.parameters, required this.functionality});

  Future<Result<T>> execute({required void Function(dynamic) onItem, Map<Object?, Object?> zoneValues = const {}}) {
    return InteractiveSystem.catchItems(function: () => functionality(parameters), onItem: onItem, zoneValues: zoneValues);
  }
}
