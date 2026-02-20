import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

const kParameterWithResultFunction = '#&[Mx.Iso.RF]?_';
const kParameterWithFunction = '#&[Mx.Iso.R]?_';

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/** */

/// Represents the status of an isolate message, including its type, identifier, and optional payload. This class is used to encapsulate information about the status of a message being processed in an isolate, allowing for communication and coordination between different parts of the system.
enum IsolateMessageStatusType { confirmation, executeResult, message }

/// Represents the status of an isolate message, including its type, identifier, and optional payload. This class is used to encapsulate information about the status of a message being processed in an isolate, allowing for communication and coordination between different parts of the system. The `IsolateMessageStatus` class contains a type that indicates the nature of the status (e.g., confirmation, execution result, or message), an identifier to track the message, and an optional payload that can carry additional data related to the status. This structure enables effective communication and handling of messages within an isolate, facilitating asynchronous operations and interactions between different components of the system.
class IsolateMessageStatus {
  final IsolateMessageStatusType type;
  final int id;
  final dynamic payload;

  const IsolateMessageStatus({required this.type, required this.id, this.payload});
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/** */

/// Represents an asynchronous executor for an isolate, containing an identifier and an executor function. This class is used to encapsulate the necessary information for executing a function asynchronously within an isolate, allowing for efficient task management and execution in a concurrent environment. The `IsolatorAsynchronousExecutor` class includes an identifier to track the executor and an `AsyncExecutor` function that defines the logic to be executed asynchronously. This structure enables effective handling of tasks and operations within an isolate, facilitating concurrent processing and improving overall performance.
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

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/** */

/// Represents a function that can be executed as part of an isolate message, containing the function logic, parameters, and a flag indicating whether the function returns a result. This class is used to encapsulate the necessary information for executing a function within an isolate, allowing for flexible and efficient task management in a concurrent environment. The `IsolateMessageResultFunction` class includes a `function` that defines the logic to be executed, `parameters` that provide the necessary input for the function, and a `returnsResult` flag that indicates whether the function is expected to return a result. This structure enables effective handling of functions within an isolate, facilitating concurrent processing and improving overall performance.
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
/** */

/// Represents a request for an isolate message, containing the type of request, an identifier, and an optional payload. This class is used to encapsulate information about a request being made within an isolate, allowing for communication and coordination between different parts of the system. The `IsolateMessageRequest` class includes a `type` that indicates the nature of the request (e.g., create function, message, or cancel), an `id` to track the request, and an optional `payload` that can carry additional data related to the request. This structure enables effective communication and handling of requests within an isolate, facilitating asynchronous operations and interactions between different components of the system.
enum IsolateMessageRequestType { createFunction, message, cancel }

/// Represents a request for an isolate message, containing the type of request, an identifier, and an optional payload. This class is used to encapsulate information about a request being made within an isolate, allowing for communication and coordination between different parts of the system. The `IsolateMessageRequest` class includes a `type` that indicates the nature of the request (e.g., create function, message, or cancel), an `id` to track the request, and an optional `payload` that can carry additional data related to the request. This structure enables effective communication and handling of requests within an isolate, facilitating asynchronous operations and interactions between different components of the system. The `IsolateMessageRequest` class serves as a fundamental component for managing and processing requests within an isolate, enabling efficient task management and coordination in a concurrent environment.  
class IsolateMessageRequest {
  final IsolateMessageRequestType type;
  final int id;
  final dynamic payload;

  const IsolateMessageRequest({required this.type, required this.id, required this.payload});
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/** */

/// Represents an interactive message for an isolate task, containing the message content and providing a method to react to the message using a list of interactive functions. This class is used to encapsulate information about an interactive message within an isolate, allowing for dynamic handling and processing of messages. The `IsolateTaskInteractiveMessage` class includes a `message` that holds the content of the message and a `react` method that iterates through a list of interactive functions, invoking each function with the message as a parameter. This structure enables flexible and responsive handling of interactive messages within an isolate, facilitating real-time interactions and dynamic behavior.
class IsolateTaskInteractiveMessage<T> {
  final T message;

  const IsolateTaskInteractiveMessage({required this.message});

  void react({required List<Function> interactiveFunctions}) {
    for (final func in interactiveFunctions.whereType<void Function(T)>()) {
      func(message);
    }
  }
}
