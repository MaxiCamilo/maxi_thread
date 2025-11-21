import 'dart:async';
import 'dart:isolate';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/isolated/server/isolated_thread_server.dart';

class SearchPointOnThreadServer with FunctionalityMixin<SendPort> {
  final int identifier;

  const SearchPointOnThreadServer({required this.identifier});

  @override
  Future<Result<SendPort>> runFuncionality() async {
    final itsServerResult = ThreadInstance.getIsolatedInstance().cast<IsolatedThreadServer>();
    if (itsServerResult.itsFailure) return itsServerResult.cast();

    final server = itsServerResult.content;

    return await server.getInvocatorByID(identifier: identifier).onCorrectFuture((x) => x.getNewSendPortFromThread());
  }
}
