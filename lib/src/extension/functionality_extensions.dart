import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';

extension FunctionalityExtensions<T> on Functionality<T> {
  Future<Result<T>> inThread(ThreadInvocator thread) {
    return thread.executeResult(parameters: InvocationParameters.only(this), function: _executeFunctionality<T>);
  }

  static Future<Result<T>> _executeFunctionality<T>(InvocationParameters parameters) {
    final item = parameters.firts<Functionality<T>>();
    return item.execute();
  }

  Future<Result<T>> inService<S extends Object>(ThreadInstance invoker) async {
    final thread = invoker.services.getServiceInvocator<S>();
    if (thread.itsFailure) return thread.cast();

    return await thread.content.executeResult<T>(parameters: InvocationParameters.only(this), function: (serv, para) => para.firts<Functionality<T>>().execute());
  }
}
