import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';

extension FunctionalityExtension<T> on Functionality<T> {
  FutureResult<T> executeOnBackground() {
    return threadSystem.backgroundService.executeResult(
      parameters: InvocationParameters.only(this),
      function: (para) {
        final func = para.first<Functionality<T>>();
        return func.execute();
      },
    );
  }
}

extension SyncFunctionalityExtension<T> on SyncFunctionality<T> {
  FutureResult<T> executeOnBackground() {
    return threadSystem.backgroundService.executeResult(
      parameters: InvocationParameters.only(this),
      function: (para) {
        final func = para.first<SyncFunctionality<T>>();
        return func.execute();
      },
    );
  }
}
