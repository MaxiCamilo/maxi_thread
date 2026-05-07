import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';

class ObtainMainTranslator with FunctionalityMixin<void> {
  const ObtainMainTranslator();

  @override
  FutureResult<void> runInternalFuncionality() async {
    final extractionResult = await threadSystem.serverConnection.executeResult(function: _getTranslatorOnServer);
    if (extractionResult.itsFailure) {
      return extractionResult.cast();
    }

    final setResult = await changeAppTranslator(extractionResult.content);
    if (!setResult.itsCorrect) {
      return setResult.asResultValue();
    }

    return voidResult;
  }

  static FutureResult<TranslatorForOrations> _getTranslatorOnServer(InvocationParameters para) {
    return appTranslator.clone();
  }
}
