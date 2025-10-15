import 'dart:isolate';

import 'package:maxi_thread/src/isolated/connections/isolated_thread_connection.dart';

class IsolatedThreadCreated {
  final Isolate isolate;
  final IsolatedThreadConnection communicator;

  const IsolatedThreadCreated({required this.isolate, required this.communicator});
}
