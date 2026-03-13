import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/shared/shared_service.dart';

class SharedValue<T extends Object> {
  final String name;

  const SharedValue({required this.name});

  Future<bool> hasInstance() {
    return SharedService.connection()
        .onCorrectFuture(
          (x) => x.execute(
            parameters: InvocationParameters.only(name),
            function: (serv, para) => serv.hasObject<T>(name: para.first<String>()),
          ),
        )
        .onNegativeFuture((x) => false.asResultValue())
        .waitContentOrThrow();
  }

  FutureResult<void> changueValue({required T value, bool removePrevious = true}) {
    return SharedService.connection().onCorrectFuture(
      (x) => x.executeResult(
        parameters: InvocationParameters.list([name, removePrevious]),
        function: (serv, para) => serv.registerObject<T>(name: para.first<String>(), item: value, removePrevious: para.second<bool>()),
      ),
    );
  }

  FutureResult<T> getValue() {
    return SharedService.connection().onCorrectFuture(
      (x) => x.executeResult(
        parameters: InvocationParameters.only(name),
        function: (serv, para) => serv.obtainSharedObject<T>(name: para.first<String>()),
      ),
    );
  }

  FutureResult<void> removeValue() {
    return SharedService.connection().onCorrectFuture(
      (x) => x.executeResult(
        parameters: InvocationParameters.only(name),
        function: (serv, para) => serv.removeSharedObject(name: para.first<String>()),
      ),
    );
  }
}
