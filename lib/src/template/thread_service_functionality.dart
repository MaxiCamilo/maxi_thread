import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/thread_connection.dart';
import 'package:maxi_thread/src/thread_singleton.dart';
import 'package:meta/meta.dart';

abstract class ThreadServiceFunctionality<S extends Object, T> with DisposableMixin, FunctionalityMixin<T> {
  @protected
  FutureResult<T> runInternalFuncionalityOnServer(S service);

  @override
  @protected
  FutureResult<T> runInternalFuncionality() async {
    final entityResult = threadSystem.getThreadEntity<S>();
    if (entityResult.itsFailure) {
      return entityResult.cast();
    }

    return await runInternalFuncionalityOnServer(entityResult.content);
  }

  FutureResult<T> executeInAnotherThread(ThreadConnection connection) {
    return connection.executeResult(parameters: InvocationParameters.only(this), function: _onAnotherThread<S, T>);
  }

  static FutureResult<T> _onAnotherThread<S extends Object, T>(InvocationParameters parameter) {
    return parameter.first<ThreadServiceFunctionality<S, T>>().execute();
  }

  FutureResult<T> executeInService() {
    final service = threadSystem.service<S>();
    return service.executeResult(parameters: InvocationParameters.only(this), function: _onService<S, T>);
  }

  static FutureResult<T> _onService<S extends Object, T>(S service, InvocationParameters parameter) {
    final item = parameter.first<ThreadServiceFunctionality<S, T>>();
    return item.runInternalFuncionalityOnServer(service);
  }
}
