import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/isolate/server/isolated_thread_server.dart';

class BackgroundIsolateClient implements BackgroundThreadService {
  final ThreadConnection serverConnection;

  const BackgroundIsolateClient({required this.serverConnection});

  @override
  Future<Result<T>> execute<T>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<T> Function(InvocationParameters para) function}) {
    return serverConnection.execute(
      function: _executeOnServer<T>,
      parameters: InvocationParameters.addParameters(original: parameters, namedParameters: {'%&¡=MXF%&': function}),
    );
  }

  static Future<T> _executeOnServer<T>(InvocationParameters parameters) {
    final function = parameters.named<FutureOr<T> Function(InvocationParameters)>('%&¡=MXF%&');
    final server = threadSystem.dynamicCastResult<IsolatedThreadServer>(errorMessage: const FixedOration(message: 'The background service can only be used within an isolated thread server')).content;
    return server.backgroundService.execute<T>(function: function, parameters: parameters).waitContentOrThrow();
  }

  @override
  Future<Result<T>> executeResult<T>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<T>> Function(InvocationParameters para) function}) {
    return serverConnection.executeResult(
      function: _executeResultOnServer<T>,
      parameters: InvocationParameters.addParameters(original: parameters, namedParameters: {'%&¡=MXFR%&': function}),
    );
  }

  static FutureResult<T> _executeResultOnServer<T>(InvocationParameters parameters) {
    final function = parameters.named<FutureOr<Result<T>> Function(InvocationParameters)>('%&¡=MXFR%&');
    final server = threadSystem.dynamicCastResult<IsolatedThreadServer>(errorMessage: const FixedOration(message: 'The background service can only be used within an isolated thread server')).content;
    return server.backgroundService.executeResult<T>(function: function, parameters: parameters);
  }
}
