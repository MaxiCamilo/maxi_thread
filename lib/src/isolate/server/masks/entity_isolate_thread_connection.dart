import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/entity_thread_connection.dart';
import 'package:maxi_thread/src/isolate/client/isolated_thread_client.dart';
import 'package:maxi_thread/src/thread_connection.dart';
import 'package:maxi_thread/src/thread_singleton.dart';

/// An implementation of the `EntityThreadConnection` interface that allows for executing functions on an entity in an isolate thread. This class uses a `ThreadConnection` to communicate with the isolate thread and execute functions on the entity. It provides methods to execute functions that return a value as well as functions that return a `Result`. The execution is performed by sending the function and its parameters to the isolate thread, where it is executed in the context of the entity associated with the thread client. This allows for effective communication and execution of functions on entities in a multi-threaded environment while ensuring proper error handling and result management.
class EntityIsolateThreadConnection<T> implements EntityThreadConnection<T> {
  final ThreadConnection connection;

  /// A constant string used as a key in the invocation parameters to identify the function that should be executed on the isolate thread. This key is used to retrieve the function from the invocation parameters when executing functions on the entity in the isolate thread, allowing for effective communication and execution of functions while ensuring that the correct function is identified and executed based on the provided parameters.
  static const _functionName = '#&(MX.FUNC.ENT)?¡';

  /// A constant string used as a key in the invocation parameters to identify the function that should be executed on the isolate thread when building a channel. This key is used to retrieve the function from the invocation parameters when building a channel on the entity in the isolate thread, allowing for effective communication and execution of functions while ensuring that the correct function is identified and executed based on the provided parameters when building channels for communication between threads.
  static const _channelFunctionName = '#&(MX.FUNC.ENT.C)?¡';

  const EntityIsolateThreadConnection(this.connection);

  @override
  /// Executes a function in the isolate thread with the provided parameters and returns the result wrapped in a `Result` type. If there is an error during execution, it returns the error wrapped in a `Result` type. If the function is executed successfully, it returns the result wrapped in a `Result` type. This method allows for effective execution of functions in the isolate thread while handling potential errors and ensuring that operations are performed correctly based on the provided parameters.
  Future<Result<R>> execute<R>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<R> Function(T serv, InvocationParameters para) function}) {
    return connection.executeResult<R>(
      function: _executeOnThread<T, R>,
      parameters: InvocationParameters.addParameters(original: parameters, namedParameters: {_functionName: function}),
    );
  }

  /// A static function that executes a function on the entity in the isolate thread based on the provided parameters. This function retrieves the thread client from the thread system, checks if the entity associated with the client is of the expected type, and then retrieves the function to execute from the invocation parameters. If any of these steps fail, it returns an appropriate error wrapped in a `Result` type. If all steps are successful, it executes the function with the entity and parameters and returns the result wrapped in a `Result` type. This function allows for effective execution of functions on entities in an isolate thread while ensuring proper error handling and result management.
  static FutureResult<R> _executeOnThread<T, R>(InvocationParameters parameters) async {
    final clientConnectionResult = threadSystem.dynamicCastResult<IsolatedThreadClient>(errorMessage: const FixedOration(message: 'The thread connection is not an client, which is required to execute entity functions'));
    if (clientConnectionResult.itsFailure) {
      return clientConnectionResult.cast();
    }

    final clientConnection = clientConnectionResult.content;
    final entity = clientConnection.entity;
    if (entity is! T) {
      return NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: FlexibleOration(message: 'The thread client does not have an entity of type %1', textParts: [T.toString()]),
      );
    }

    final function = parameters.namedParameters[_functionName];
    if (function == null) {
      return NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: const FixedOration(message: 'The function to execute was not found in the invocation parameters'),
      );
    }
    if (function is! FutureOr<R> Function(T serv, InvocationParameters para)) {
      return NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: const FixedOration(message: 'The function to execute has an invalid type'),
      );
    }

    return await function(entity, parameters).asResCatchException();
  }

  @override
  /// Executes a function in the isolate thread with the provided parameters and returns the result wrapped in a `Result` type. If there is an error during execution, it returns the error wrapped in a `Result` type. If the function is executed successfully, it returns the result wrapped in a `Result` type. This method allows for effective execution of functions in the isolate thread while handling potential errors and ensuring that operations are performed correctly based on the provided parameters.
  Future<Result<R>> executeResult<R>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<R>> Function(T serv, InvocationParameters para) function}) {
    return connection.executeResult<R>(
      function: _executeResultOnThread<T, R>,
      parameters: InvocationParameters.addParameters(original: parameters, namedParameters: {_functionName: function}),
    );
  }

  /// A static function that executes a function that returns a `Result` on the entity in the isolate thread based on the provided parameters. This function retrieves the thread client from the thread system, checks if the entity associated with the client is of the expected type, and then retrieves the function to execute from the invocation parameters. If any of these steps fail, it returns an appropriate error wrapped in a `Result` type. If all steps are successful, it executes the function with the entity and parameters and returns the result wrapped in a `Result` type. This function allows for effective execution of functions that return results on entities in an isolate thread while ensuring proper error handling and result management.
  static FutureResult<R> _executeResultOnThread<T, R>(InvocationParameters parameters) async {
    final clientConnectionResult = threadSystem.dynamicCastResult<IsolatedThreadClient>(errorMessage: const FixedOration(message: 'The thread connection is not an client, which is required to execute entity functions'));
    if (clientConnectionResult.itsFailure) {
      return clientConnectionResult.cast();
    }

    final clientConnection = clientConnectionResult.content;
    final entity = clientConnection.entity;
    if (entity is! T) {
      return NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: FlexibleOration(message: 'The thread client does not have an entity of type %1', textParts: [T.toString()]),
      );
    }

    final function = parameters.namedParameters[_functionName];
    if (function == null) {
      return NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: const FixedOration(message: 'The function to execute was not found in the invocation parameters'),
      );
    }
    if (function is! FutureOr<Result<R>> Function(T serv, InvocationParameters para)) {
      return NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: const FixedOration(message: 'The function to execute has an invalid type'),
      );
    }

    return function(entity, parameters);
  }

  @override
  FutureResult<Channel<S, R>> buildChannel<R, S>({
    InvocationParameters parameters = InvocationParameters.empty,
    required FutureOr<Result<void>> Function(T serv, Channel<R, S> channel, InvocationParameters para) function,
  }) async {
    return connection.buildChannel(
      function: _buildChannelOnThread<T, R, S>,
      parameters: InvocationParameters.addParameters(original: parameters, namedParameters: {_channelFunctionName: function}),
    );
  }

  static FutureResult<void> _buildChannelOnThread<T, R, S>(Channel<R, S> channel, InvocationParameters parameters) async {
    final clientConnectionResult = threadSystem.dynamicCastResult<IsolatedThreadClient>(errorMessage: const FixedOration(message: 'The thread connection is not an client, which is required to build entity channels'));
    if (clientConnectionResult.itsFailure) {
      return clientConnectionResult.cast();
    }

    final clientConnection = clientConnectionResult.content;
    final entity = clientConnection.entity;
    if (entity is! T) {
      return NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: FlexibleOration(message: 'The thread client does not have an entity of type %1', textParts: [T.toString()]),
      );
    }

    final function = parameters.namedParameters[_channelFunctionName];
    if (function == null) {
      return NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: const FixedOration(message: 'The function to execute was not found in the invocation parameters'),
      );
    }
    if (function is! FutureOr<Result<void>> Function(T serv, Channel<R, S> channel, InvocationParameters para)) {
      return NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: const FixedOration(message: 'The function to execute has an invalid type'),
      );
    }

    return await function(entity, channel, parameters);
  }
}
