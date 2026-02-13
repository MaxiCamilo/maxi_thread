import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

const kParameterWithResultFunction = '#&[Mx.Iso.RF]?_';
const kParameterWithFunction = '#&[Mx.Iso.R]?_';

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

enum IsolateMessageStatusType { confirmation, executeResult, message }

class IsolateMessageStatus {
  final IsolateMessageStatusType type;
  final int id;
  final dynamic payload;

  const IsolateMessageStatus({required this.type, required this.id, this.payload});
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class IsolatorAsynchronousExecutor<T> {
  final int identifier;
  final AsyncExecutor<T> executor;

  const IsolatorAsynchronousExecutor({required this.identifier, required this.executor});
}
/*
class IsolateMessageFunction<T> {
  final FutureOr<T> Function(InvocationParameters para) function;
  final InvocationParameters parameters;

  IsolateMessageFunction({required this.function, required this.parameters});

  IsolatorAsynchronousExecutor<T> buildExecutor(int identifier) {
    return IsolatorAsynchronousExecutor<T>(
      identifier: identifier,
      executor: AsyncExecutor.function(function: () => function(parameters)),
    );
  }
}*/

class IsolateMessageResultFunction<T> {
  final FutureOr Function(InvocationParameters para) function;
  final InvocationParameters parameters;
  final bool returnsResult;

  const IsolateMessageResultFunction({required this.function, required this.parameters, required this.returnsResult});

  FutureResult<T> execute() async {
    final result = await function(parameters);
    if (returnsResult) {
      return result as Result<T>;
    } else {
      return ResultValue<T>(content: result as T);
    }
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

enum IsolateMessageRequestType { createFunction, message, cancel }

class IsolateMessageRequest {
  final IsolateMessageRequestType type;
  final int id;
  final dynamic payload;

  const IsolateMessageRequest({required this.type, required this.id, required this.payload});
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class IsolateTaskInteractiveMessage<T> {
  final T message;

  const IsolateTaskInteractiveMessage({required this.message});

  void react({required List<Function> interactiveFunctions}) {
    for (final func in interactiveFunctions.whereType<void Function(T)>()) {
      func(message);
    }
  }
}
