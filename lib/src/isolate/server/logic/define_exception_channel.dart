import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/isolate/exception_channel/isolate_exception_channel_client.dart';

class DefineExceptionChannel with FunctionalityMixin<void> {
  const DefineExceptionChannel();

  @override
  FutureResult<void> runInternalFuncionality() async {
    final exc = IsolateExceptionChannelClient();
    final initializationResult = await exc.initialize();
    if (initializationResult.itsFailure) {
      return initializationResult.cast();
    }

    final changeChannelResult = appManager.changeExceptionChannel(exc);
    if (changeChannelResult.itsFailure) {
      return changeChannelResult.cast();
    }

    return voidResult;
  }
}
