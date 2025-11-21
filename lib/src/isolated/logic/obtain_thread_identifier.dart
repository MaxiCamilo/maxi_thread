import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';

class ObtainThreadIdentifier with FunctionalityMixin<int> {
  const ObtainThreadIdentifier();

  @override
  Future<Result<int>> runFuncionality() async {
    final instanceResult = ThreadInstance.getIsolatedInstance();
    if (instanceResult.itsFailure) return instanceResult.cast();

    return instanceResult.content.identifier.asResultValue();
  }
}
