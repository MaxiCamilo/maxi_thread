import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';

class ObtainMainTranslator with FunctionalityMixin<void> {
  const ObtainMainTranslator();

  @override
  FutureResult<void> runInternalFuncionality() async {
    final idResult = await threadSystem.serverConnection.executeResult(function: _getUniqueID);
    if (idResult.itsFailure) {
      return idResult.cast();
    }

    if (idResult.content == appTranslator.uniqueID) {
      return voidResult;
    }

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

  static Result<int> _getUniqueID(InvocationParameters para) {
    return appTranslator.uniqueID.asResultValue();
  }

  static FutureResult<TranslatorForOrations> _getTranslatorOnServer(InvocationParameters para) {
    return appTranslator.clone();
  }
}
