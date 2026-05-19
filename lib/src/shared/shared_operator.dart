import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/shared/shared_service.dart';

class SharedOperator<T extends Object> implements Disposable, EntityThreadConnection<T> {
  static final Map<int, (String, dynamic)> _localOperators = {};

  final String name;

  const SharedOperator({required this.name});

  @override
  bool get itWasDiscarded => false;

  FutureResult<bool> hasInstance() {
    return SharedService.connection().onCorrectFuture(
      (x) => x.executeResult(
        parameters: InvocationParameters.list([name, T]),
        function: (serv, para) => serv.isOperatorRegistered(name: para.first<String>(), operatorType: para.second<Type>()),
      ),
    );
  }

  FutureResult<void> register({required T newOperator, bool removePrevious = true}) {
    return SharedService.connection().onCorrectFuture((service) async {
      final exitstResult = await hasInstance();
      if (exitstResult.itsFailure) {
        return exitstResult.cast();
      }

      if (newOperator is Disposable && newOperator.itWasDiscarded) {
        return NegativeResult.controller(
          code: ErrorCode.invalidFunctionality,
          message: FlexibleOration(message: 'The operator provided for registration is already discarded', textParts: [name]),
        );
      }

      if (exitstResult.content) {
        if (removePrevious) {
          final removeResult = await service.execute(
            parameters: InvocationParameters.list([name]),
            function: (serv, para) => serv.removeOperator(name: para.first<String>()),
          );
          if (removeResult.itsFailure) {
            return removeResult.cast();
          }
        } else {
          return NegativeResult.controller(
            code: ErrorCode.invalidFunctionality,
            message: FlexibleOration(message: 'An operator with the name %1 is already registered', textParts: [name]),
          );
        }
      }

      if (_localOperators.values.any((entry) => entry.$1 == name)) {
        return NegativeResult.controller(
          code: ErrorCode.invalidFunctionality,
          message: FlexibleOration(message: 'The same operator instance cannot be registered with multiple names. The provided operator is already registered with the name %1', textParts: [name]),
        );
      }

      final newID = _localOperators.isEmpty ? 1 : _localOperators.keys.maximumOf((x) => x) + 1;
      _localOperators[newID] = (name, newOperator);

      return await service
          .executeResult(
            parameters: InvocationParameters.list([name, newID, T]),
            function: (serv, para) => serv.registerOperator(name: para.first<String>(), operatorId: para.second<int>(), operatorType: para.third<Type>()),
          )
          .injectNegativeLogic((_) {
            _localOperators.remove(newID);
          })
          .injectLogic((_) async {
            if (newOperator is Disposable) {
              newOperator.onDispose.whenComplete(dispose);
            }

            return voidResult;
          });
    });
  }

  static FutureResult<R> _invoke<T extends Object, R>(InvocationParameters parameters) async {
    //required FutureOr<Result<R>> Function(T,InvocationParameters) function
    final localOperator = _localOperators[parameters.named<int>('%&&SharedOperatorID&&%')];
    if (localOperator == null) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'No operator is registered with the provided ID (%1)', textParts: [parameters.named<int>('%&&SharedOperatorID&&%')]),
      );
    }

    if (localOperator.$1 != parameters.named<String>('%&&SharedOperatorName&&%')) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(
          message: 'The operator registered with the provided ID (%1) has a different name than expected (%2)',
          textParts: [parameters.named<int>('%&&SharedOperatorID&&%'), parameters.named<String>('%&&SharedOperatorName&&%')],
        ),
      );
    }

    if (localOperator.$2 is! T) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'The operator registered with the provided ID (%1) is not of the expected type', textParts: [parameters.named<int>('%&&SharedOperatorID&&%')]),
      );
    }

    final function = parameters.named<FutureOr<Result<R>> Function(T, InvocationParameters)>('%&&SharedOperatorFunc&&%');
    return await function(localOperator.$2, parameters);
  }

  @override
  Future<Result<R>> executeResult<R>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<R>> Function(T oper, InvocationParameters para) function}) async {
    final itsLocal = _localOperators.values.selectItem((entry) => entry.$1 == name);
    if (itsLocal != null) {
      final localOperator = itsLocal.$2;
      if (localOperator is! T) {
        return NegativeResult.controller(
          code: ErrorCode.invalidFunctionality,
          message: FlexibleOration(message: 'The operator registered with the name %1 is not of the expected type', textParts: [name]),
        );
      }

      return await function(localOperator, parameters);
    }

    final instanceIdResult = await SharedService.connection().onCorrectFuture(
      (service) => service.executeResult(
        parameters: InvocationParameters.list([name, T]),
        function: (serv, para) => serv.obtainOperatorAddress(name: para.first<String>(), operatorType: para.second<Type>()),
      ),
    );

    if (instanceIdResult.itsFailure) {
      return instanceIdResult.cast();
    }

    final threadResult = await threadSystem.obtainConnectionFromIdentifier(threadIdentifier: instanceIdResult.content.$1);
    if (threadResult.itsFailure) {
      return threadResult.cast();
    }

    final newParameters = InvocationParameters.addParameters(
      original: parameters,
      namedParameters: {'%&&SharedOperatorFunc&&%': function, '%&&SharedOperatorName&&%': name, '%&&SharedOperatorID&&%': instanceIdResult.content.$2},
    );

    return await threadResult.content.executeResult(parameters: newParameters, function: _invoke<T, R>);
  }

  @override
  Future<Result<R>> execute<R>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<R> Function(T serv, InvocationParameters para) function}) {
    return executeResult(
      parameters: InvocationParameters.addParameters(original: parameters, namedParameters: {'%&&SharedOperatorRawFunc&&%': function}),
      function: (serv, para) async {
        final function = para.named<FutureOr<R> Function(T serv, InvocationParameters para)>('%&&SharedOperatorRawFunc&&%');
        return volatileFuture(
          error: (ex, st) => ExceptionResult(
            exception: ex,
            stackTrace: st,
            message: const FixedOration(message: 'An error occurred while executing the function'),
          ),
          function: () async {
            return await function(serv, para);
          },
        );
      },
    );
  }

  @override
  FutureResult<Channel<S, R>> buildChannel<R, S>({
    InvocationParameters parameters = InvocationParameters.empty,
    required FutureOr<Result<dynamic>> Function(T serv, Channel<R, S> channel, InvocationParameters para) function,
  }) async {
    final itsLocal = _localOperators.values.selectItem((entry) => entry.$1 == name);
    if (itsLocal != null) {
      final localOperator = itsLocal.$2;
      if (localOperator is! T) {
        return NegativeResult.controller(
          code: ErrorCode.invalidFunctionality,
          message: FlexibleOration(message: 'The operator registered with the name %1 is not of the expected type', textParts: [name]),
        );
      }

      final mainChannel = MasterChannel<S, R>();
      final channelResult = mainChannel.buildConnector();
      if (channelResult.itsFailure) {
        return channelResult.cast();
      }

      scheduleMicrotask(() async {
        await volatileFuture(
          error: (ex, st) => ExceptionResult(
            exception: ex,
            stackTrace: st,
            message: const FixedOration(message: 'An error occurred while executing the channel function'),
          ),
          function: () => function(localOperator, channelResult.content, parameters),
        ).logIfFails(errorName: 'SharedOperator -> buildChannel: Failed to execute channel function for operator name: $name');

        mainChannel.dispose();
      });

      return mainChannel.asResultValue();
    }

    final instanceIdResult = await SharedService.connection().onCorrectFuture(
      (service) => service.executeResult(
        parameters: InvocationParameters.list([name, T]),
        function: (serv, para) => serv.obtainOperatorAddress(name: para.first<String>(), operatorType: para.second<Type>()),
      ),
    );

    if (instanceIdResult.itsFailure) {
      return instanceIdResult.cast();
    }

    final threadResult = await threadSystem.obtainConnectionFromIdentifier(threadIdentifier: instanceIdResult.content.$1);
    if (threadResult.itsFailure) {
      return threadResult.cast();
    }

    return await threadResult.content.buildChannel(
      parameters: InvocationParameters.addParameters(
        original: parameters,
        namedParameters: {'%&&SharedOperatorName&&%': name, '%&&SharedOperatorID&&%': instanceIdResult.content.$2, '%&&SharedOperatorFunc&&%': function},
      ),
      function: _invokeChannelFunction<T, R, S>,
    );
  }

  static FutureResult<void> _invokeChannelFunction<T extends Object, R, S>(Channel<R, S> channel, InvocationParameters parameters) async {
    final function = parameters.named<FutureOr<Result<dynamic>> Function(T, Channel<R, S>, InvocationParameters)>('%&&SharedOperatorFunc&&%');
    final operatorName = parameters.named<String>('%&&SharedOperatorName&&%');
    final operatorId = parameters.named<int>('%&&SharedOperatorID&&%');

    final localOperator = _localOperators[operatorId];
    if (localOperator == null) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'No operator is registered with the provided ID (%1)', textParts: [operatorId]),
      );
    }

    if (localOperator.$1 != operatorName) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'The operator registered with the provided ID (%1) has a different name than expected (%2)', textParts: [operatorId, operatorName]),
      );
    }

    if (localOperator.$2 is! T) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'The operator registered with the provided ID (%1) is not of the expected type', textParts: [operatorId]),
      );
    }

    return await function(localOperator.$2, channel, parameters);
  }

  @override
  TinyEvent<dynamic> get onDispose {
    final tinyManager = TinyEventManager();

    scheduleMicrotask(() async {
      final result = await executeResult(
        function: (serv, para) async {
          if (serv is Disposable) {
            await (serv as Disposable).onDispose.toFuture();
            return voidResult;
          } else {
            return NegativeResult.controller(
              code: ErrorCode.invalidFunctionality,
              message: FlexibleOration(message: 'The operator registered with the name %1 is not disposable, so it cannot be observed for disposal', textParts: [name]),
            );
          }
        },
      );
      if (result.itsFailure) {
        tinyManager.triggerError(result.error, StackTrace.current);
      } else {
        tinyManager.triggerEvent(null);
      }
    });

    return tinyManager.createEvent(temporal: true);
  }

  @override
  void dispose() {
    executeResult(
      function: (serv, para) {
        _localOperators.removeWhere((key, value) => value.$1 == name);

        SharedService.connection()
            .onCorrectFuture(
              (x) => x.execute(
                parameters: InvocationParameters.only(name),
                function: (serv, para) => serv.removeOperator(name: para.first<String>()),
              ),
            )
            .logIfFails(errorName: 'SharedOperator -> dispose: Failed to remove operator from SharedService for operator name: $name');

        if (serv is Disposable) {
          (serv as Disposable).dispose();
        }
        return voidResult;
      },
    );
  }
}
